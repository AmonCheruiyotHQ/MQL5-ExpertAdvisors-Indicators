//+------------------------------------------------------------------+
//|                                                 15MIN_200EMA.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object

//---- input parameters
//input bool   Reverse         = true;
input double InpTakeProfit   = 100;
input double InpStopLoss     = 40;
input double Lots            = 0.01;
//input double InpTrailingStop = 20;
input int    ShortEma     =50;
input int    LongEma         =200;

int    handle_iMAShort;                      // variable for storing the handle of the iMA indicator 
int    handle_iMALong;                       // variable for storing the handle of the iMA indicator 
uchar  digits_adjust=-1;
double ExtTakeProfit=0.0;
double ExtStopLoss=0.0;
double ExtTrailingStop=0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//----
   if(Bars(Symbol(),Period())<100)
     {
      Print("bars less than 100");
      return(INIT_FAILED);
     }
//---
   m_symbol.Name(Symbol());
   m_symbol.Refresh();
   RefreshRates();
   m_trade.SetExpertMagicNumber(12345);
//--- tuning for 3 or 5 digits
   digits_adjust=10;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
     {
      digits_adjust=10;
     }
   ExtTakeProfit=InpTakeProfit*digits_adjust;
//---
   if(ExtTakeProfit<20)
     {
      Print("TakeProfit less than 20 point");
      return(INIT_FAILED);  // check ExtTakeProfit
     }//---
   ExtStopLoss=InpStopLoss*digits_adjust;
   //ExtTrailingStop=InpTrailingStop*digits_adjust;
//--- create handle of the indicator iMA
   handle_iMAShort=iMA(Symbol(),Period(),ShortEma,0,MODE_EMA,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iMAShort==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMALong=iMA(Symbol(),Period(),LongEma,0,MODE_EMA,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iMALong==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ulong  m_ticket=0;
   double SEma,LEma;
   double pointValue =  m_symbol.Point();
   double toleranceRange = 200 * Point(); 
//---
   SEma = iMAGet(handle_iMAShort,0);
   LEma = iMAGet(handle_iMALong,0);
////---
   if(!RefreshRates())
      return;
//---   
   int pos_total=PositionsTotal();
   if(pos_total<3)
     {
      if(SEma > LEma && m_symbol.Bid() >= LEma - toleranceRange && m_symbol.Bid() <= LEma + toleranceRange)
        {
         if(m_trade.Buy(Lots,Symbol(),m_symbol.Ask(),m_symbol.Ask()-ExtStopLoss*Point(),
            m_symbol.Ask()+ExtTakeProfit*Point(),"EMA_CROSS"))
           {
            m_ticket=m_trade.ResultDeal();
            Print("Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription(),
                  ", m_ticket of deal: ",m_trade.ResultDeal());
           }
         else
           {
            Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription(),
                  ", m_ticket of deal: ",m_trade.ResultDeal());
           }
         return;
        }
      /*if(LEma > SEma && m_symbol.Ask() >= LEma - toleranceRange && m_symbol.Ask() >= LEma - toleranceRange)
        {
         if(m_trade.Sell(Lots,Symbol(),m_symbol.Bid(),m_symbol.Bid()+ExtStopLoss*Point(),
            m_symbol.Bid()-ExtTakeProfit*Point(),"EMA_CROSS"))
           {
            m_ticket=m_trade.ResultDeal();
            Print("Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription(),
                  ", m_ticket of deal: ",m_trade.ResultDeal());
           }
         else
           {
            Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription(),
                  ", m_ticket of deal: ",m_trade.ResultDeal());
           }
         return;
        } */
      return;
     }

//---
   return;
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(const int handle,const int index)
  {
   double MA[];
   ArraySetAsSeries(MA,true);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle,0,0,index+1,MA)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(MA[index]);
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
