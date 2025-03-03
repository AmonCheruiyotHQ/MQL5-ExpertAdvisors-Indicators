//+------------------------------------------------------------------+
//|                                               CROSSOVER v1.1.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                        amoncheruiyothq@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, amoncheruiyot."
#property link      "https://www.amoncheruiyot.com"
#property version   "1.0"

//+------------------------------------------------------------------+
//| 01 Setup - Include , Inputs, Variables                           |
//+------------------------------------------------------------------+

#include <Trade/Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
CPositionInfo  m_position;                   // m_trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
input group             "===== EMA_Settings ====="
input int                  ma1_period              =10;                 // Period of MA1
input ENUM_MA_METHOD       ma1_method              =MODE_EMA;           // Smoothing of MA1
input ENUM_APPLIED_PRICE   ma1_applied_price       =PRICE_CLOSE;        // Price of MA1
input int                  ma2_period              =20;                 // Period of MA2
input ENUM_MA_METHOD       ma2_method              =MODE_EMA;           // Smoothing of MA2
input ENUM_APPLIED_PRICE   ma2_applied_price       =PRICE_CLOSE;        // Price of MA2

input group           "===== Orders_Settings ====="
static input int           EXPERT_MAGIC            = 100009;           // MagicNumber of the expert
input double               Lots                    = 0.01;             // Lotsize
input int                  TpPoints                = 600;              // Take-Profit in Points
input int                  SlPoints                = 600;              // Stop-Loss in Points

input group             "===== Trading_Days ====="
input bool              TradeOnMonday                 =true; // Trade on Monday
input string            MondayStartTime               ="00:00"; // Monday Start-Time
input string            MondayStopTime                ="17:00"; // Monday Stop-Time
input bool              TradeOnTuesday                =true; // Trade on Tuesday
input string            TuesdayStartTime              ="00:00"; // Tuesday Start-Time
input string            TuesdayStopTime               ="17:00"; // Tuesday Stop-Time
input bool              TradeOnWednesday              =true; // Trade on Wednesday
input string            WednesdayStartTime            ="00:00"; // Wednesday Start-Time
input string            WednesdayStopTime             ="17:00"; // Wednesday Stop-Time
input bool              TradeOnThursday               =true; // Trade on Thursday
input string            ThursdayStartTime             ="00:00"; // Thursday Start-Time
input string            ThursdayStopTime              ="17:00"; // Thursday Stop-Time
input bool              TradeOnFriday                 =true; // Trade on Friday
input string            FridayStartTime               ="00:00"; // Friday Start-Time
input string            FridayStopTime                ="17:00"; // Friday Stop-Time
input bool              TradeOnSaturday               =false; // Trade on Saturday
input string            SaturdayStartTime             ="00:00"; // Saturday Start-Time
input string            SaturdayStopTime              ="00:00"; // Saturday StopTime
input bool              TradeOnSunday                 =false; // Trade on Sunday
input string            SundayStartTime               ="00:00"; // Sunday Start-Time
input string            SundayStopTime                ="17:00"; // Sunday Stop-Time

input group             "===== BREAK_EVEN ====="
input bool           USEMOVETOBREAKEVEN=true; //Enable "Break Even"
input int            AdditionalProfit = 0;       // Additional profit in points to add to BE
// --- setup tables and variables

double iMA09_Array[], iMA26_Array[];                                  // Creates data table to store SMA values
int iMA09_handle, iMA26_handle;
double iMA09_1, iMA09_2, iMA26_1, iMA26_2;
bool              ExtTradeOnMonday                 =false; // Trade on Monday
bool              ExtTradeOnTuesday                =false; // Trade on Tuesday
bool              ExtTradeOnWednesday              =false; // Trade on Wednesday
bool              ExtTradeOnThursday               =false; // Trade on Thursday
bool              ExtTradeOnFriday                 =false; // Trade on Friday
bool              ExtTradeOnSaturday               =false; // Trade on Saturday
bool              ExtTradeOnSunday                 =false; // Trade on Sunday

//+------------------------------------------------------------------+
//| 02 Initialization function of the expert                         |
//+------------------------------------------------------------------+
int OnInit()
  {

   m_trade.SetExpertMagicNumber(EXPERT_MAGIC);
   m_symbol.Refresh();
   m_symbol.Name(Symbol());
   m_symbol.Refresh();
//-------------------------------------------------------------------+
   ExtTradeOnMonday                 =TradeOnMonday; // Trade on Monday
   ExtTradeOnTuesday                =TradeOnTuesday; // Trade on Tuesday
   ExtTradeOnWednesday              =TradeOnWednesday; // Trade on Wednesday
   ExtTradeOnThursday               =TradeOnThursday; // Trade on Thursday
   ExtTradeOnFriday                 =TradeOnFriday; // Trade on Friday
   ExtTradeOnSaturday               =TradeOnSaturday; // Trade on Saturday
   ExtTradeOnSunday                 =TradeOnSunday; // Trade on Sunday
//-------------------------------------------------------------------+

   ArraySetAsSeries(iMA09_Array,true);  // Ensures latest SMA data is indexed from shift 0
   ArraySetAsSeries(iMA26_Array,true);
   iMA09_handle = iMA(Symbol(), PERIOD_CURRENT, ma1_period, 0, ma1_method, ma1_applied_price); // Getting the Control Panel/Handle for SMA
   iMA26_handle = iMA(Symbol(), PERIOD_CURRENT, ma2_period, 0, ma2_method, ma2_applied_price); // Getting the Control Panel/Handle for SMA

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| 03 Deinitialization function of the expert                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   IndicatorRelease(iMA09_handle); //Release the iMA indicator
   ChartIndicatorDelete(0,0,ChartIndicatorName(0,0,0)); //iterate to remove several charts
   ArrayFree(iMA09_Array); // free the dynamic array of data

   IndicatorRelease(iMA26_handle); //Release the iMA indicator
   ChartIndicatorDelete(0,0,ChartIndicatorName(0,0,1)); //iterate to remove several charts
   ArrayFree(iMA26_Array); // free the dynamic array of data

  }
//+------------------------------------------------------------------+
//| 04 "Tick" event handler function                                 |
//+------------------------------------------------------------------+
void OnTick()
  {
   ulong posTicketssell;
   ulong posTicketsbuy;
   ulong posTickets;

//---close all positions at end of trading day
   if(TimeTradeServer()>= StringToTime("23:55")&&TimeTradeServer()<= StringToTime("23:59"))
     {
      positionDelete(posTickets);
      m_trade.PositionClose(posTickets);

      positionDeleteSell(posTicketssell);
      m_trade.PositionClose(posTicketssell);

      positionDeleteBuy(posTicketsbuy);
      m_trade.PositionClose(posTicketsbuy);
     
     }

//--- User Function to stop code from here untill new bar, No extra brace needed
   if(!is_new_bar())
     {
      return;
     }

   int iMA09_err = CopyBuffer(iMA09_handle, 0,0, 3, iMA09_Array); //  Collects data of the 0th line (if more then one) from shift 0 to shift 3
   int iMA26_err = CopyBuffer(iMA26_handle, 0,0, 3, iMA26_Array); //  Collects data of the 0th line (if more then one) from shift 0 to shift 3
   if(iMA09_err<0 || iMA26_err<0)                                    //in case of errors
     {
      Print("Failed to copy data from the indicator buffer or price chart buffer");  //then print the relevant error message into the log file
      return;    //and exit the function
     }

   ChartIndicatorAdd(0,0,iMA09_handle);
   ChartIndicatorAdd(0,0,iMA26_handle);

//--- calculations for EMA  crossover
   iMA09_1 = iMA09_Array[1];
   iMA09_1 = NormalizeDouble(iMA09_1,Digits());
   iMA09_2 = iMA09_Array[2];
   iMA09_2 = NormalizeDouble(iMA09_2,Digits());
   iMA26_1 = iMA26_Array[1];
   iMA26_1 = NormalizeDouble(iMA26_1,Digits());
   iMA26_2 = iMA26_Array[2];
   iMA26_2 = NormalizeDouble(iMA26_2,Digits());


//+-------------preparation for Trades processing, assignment of price to be used

   double sl, tp, price;
//--- Close Current Position
   if((!IsTradingTime() && IsTradingDay()) || (!IsTradingTime() && !IsTradingDay()) || (IsTradingTime() && !IsTradingDay()))
     {
      if(USEMOVETOBREAKEVEN)
         BreakEven();

      //      if(iMA09_1 > iMA26_1)  // buy
      //        {
      //         positionDeleteSell(posTicketssell);
      //         m_trade.PositionClose(posTicketssell);
      //        }
      //
      //      if(iMA09_1 < iMA26_1)  // sell
      //        {
      //         positionDeleteBuy(posTicketsbuy);
      //         m_trade.PositionClose(posTicketsbuy);
      //        }
      //positionDelete(posTicket);
      //m_trade.PositionClose(posTicket);
     }

   if(iMA09_1 < iMA26_1 && iMA09_2 < iMA26_2)
     {
      //Print("Still on sell side");
      //Print("GreaterThan = sma9 = ", iMA09_1, ", sam26 = ", iMA26_1, "= 2sma9 = ", iMA09_2, ", 2sam26 = ", iMA26_2);
      return;
     }

   if(iMA09_1 > iMA26_1 && iMA09_2 > iMA26_2)
     {
      //Print("Still on buy side");
      //Print("LessThan = sma9 = ", iMA09_1, ", sam26 = ", iMA26_1, "= 2sma9 = ", iMA09_2, ", 2sam26 = ", iMA26_2);
      return;
     }

//--- Close Current Position
   if((!IsTradingTime() && IsTradingDay()) || (!IsTradingTime() && !IsTradingDay()) || (IsTradingTime() && !IsTradingDay()))
     {
      //if(USEMOVETOBREAKEVEN)
      //   BreakEven();

      if(iMA09_1 > iMA26_1)  // buy
        {
         positionDeleteSell(posTicketssell);
         m_trade.PositionClose(posTicketssell);
        }

      if(iMA09_1 < iMA26_1)  // sell
        {
         positionDeleteBuy(posTicketsbuy);
         m_trade.PositionClose(posTicketsbuy);
        }
      //positionDelete(posTicket);
      //m_trade.PositionClose(posTicket);
     }

   if(IsTradingDay() && IsTradingTime())
     {
      if(iMA09_1 > iMA26_1)  // buy
        {
         Print("Buy Signal in");
         price=(double)SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         SLTPpriceBuy(price, sl, tp);
         if(GetProfitSells()>=0)
           {
            BreakEven();
           }
         else
           {
            positionDeleteSell(posTicketssell);
            m_trade.PositionClose(posTicketssell);
           }
         if(CountBuySide()==0)
           {
            m_trade.Buy(Lots,NULL,0,sl,tp,"Buy"); // then long
           }
        }

      if(iMA09_1 < iMA26_1)  // sell
        {
         Print("Sell Signal in");
         price=(double)SymbolInfoDouble(_Symbol,SYMBOL_BID);
         SLTPpriceSell(price, sl, tp);
         if(GetProfitBuys()>=0)
           {
            BreakEven();
           }
         else
           {
            positionDeleteBuy(posTicketsbuy);
            m_trade.PositionClose(posTicketsbuy);
           }
         if(CountSellSide()==0)
           {
            m_trade.Sell(Lots,NULL,0,sl,tp,"sell"); // then short
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| 05 Expert UserDefined function                                   |
//+------------------------------------------------------------------+
void SLTPpriceBuy(double &price, double &sl, double &tp)
  {
   if(TpPoints == 0)
     {
      tp = 0;
     }
   else
     {
      tp = price + TpPoints*Point();
     };
   tp = NormalizeDouble(tp,Digits());
   if(SlPoints == 0)
     {
      sl = 0;
     }
   else
     {
      sl = price - SlPoints*Point();
     };
   sl = NormalizeDouble(sl,Digits());
   price = NormalizeDouble(price,Digits());
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SLTPpriceSell(double &price, double &sl, double &tp)
  {
   if(TpPoints == 0)
     {
      tp = 0;
     }
   else
     {
      tp = price - TpPoints*Point();
     };
   tp = NormalizeDouble(tp,Digits());
   if(SlPoints == 0)
     {
      sl = 0;
     }
   else
     {
      sl = price + SlPoints*Point();
     };
   sl = NormalizeDouble(sl,Digits());
   price = NormalizeDouble(price,Digits());
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void positionDeleteBuy(ulong &posTicketsbuy)
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(m_position.SelectByIndex(i))
         if(PositionGetString(POSITION_SYMBOL)==m_symbol.Name())
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
               posTicketsbuy = PositionGetTicket(i);  // Scans all open orders
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void positionDelete(ulong &posTickets)
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      posTickets = PositionGetTicket(i);  // Scans all open orders
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void positionDeleteSell(ulong &posTicketssell)
  {
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(m_position.SelectByIndex(i))
         if(PositionGetString(POSITION_SYMBOL)==m_symbol.Name())
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
               posTicketssell = PositionGetTicket(i);  // Scans all open orders
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllBuys()
  {
   int total=PositionsTotal();
   for(int k=total-1; k>=0; k--)
      if(m_position.SelectByIndex(k))
         if(PositionGetString(POSITION_SYMBOL)==m_symbol.Name())
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               m_trade.PositionClose(PositionGetInteger(POSITION_TICKET), 3);
               Print("All Buy Positions Closed Successfully");
              }
  }
//----------------------------06--------------------------------------
int CountBuySide()
  {
   int buys = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name())
            if(m_position.PositionType() == POSITION_TYPE_BUY)
              {
               buys++;
              }

   return (buys);
  }

//----------------------------07--------------------------------------
int CountSellSide()
  {
   int count = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name())
            if(m_position.PositionType()  == POSITION_TYPE_SELL)
              {
               count++;
              }

   return (count);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllSells()
  {
   int total=PositionsTotal();
   for(int k=total-1; k>=0; k--)
      if(m_position.SelectByIndex(k))
         if(m_position.Symbol()==m_symbol.Name())
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               m_trade.PositionClose(PositionGetInteger(POSITION_TICKET), 3);
               Print("All Sell Positions Closed Successfully");
              }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//--- User Function to stop code untill new bar, No extra brace needed
bool is_new_bar()
  {
   static datetime last_time = 0;
   datetime curr_time = (datetime)SeriesInfoInteger(Symbol(), PERIOD_CURRENT, SERIES_LASTBAR_DATE);
   if(last_time == curr_time)
      return false;
   last_time = curr_time;
   return true;
  }
//+------------------------------------------------------------------+
//|    COUNT ALL PROFITS OR LOSS for buys                            |
//+------------------------------------------------------------------+
double GetProfitBuys()
  {
   double profit = 0;
   double floating = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      string symbol = PositionGetSymbol(i);
      if(m_position.SelectByIndex(i))
         if(symbol == m_symbol.Name())
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
              {
               profit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+AccountInfoDouble(ACCOUNT_COMMISSION_BLOCKED);
               floating = profit;
              }
           }//2
     }//1
   return (floating);
  }//0
//+------------------------------------------------------------------+
//|    COUNT ALL PROFITS OR LOSS    For sells                        |
//+------------------------------------------------------------------+
double GetProfitSells()
  {
   double profit = 0;
   double floating = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      string symbol = PositionGetSymbol(i);
      if(m_position.SelectByIndex(i))
         if(symbol == m_symbol.Name())
           {
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
              {
               profit += PositionGetDouble(POSITION_PROFIT)+PositionGetDouble(POSITION_SWAP)+AccountInfoDouble(ACCOUNT_COMMISSION_BLOCKED);
               floating = profit;
              }
           }//2
     }//1
   return (floating);
  }//0
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
bool IsTradingDay()
  {
   MqlDateTime STime;
   datetime time_current=TimeTradeServer();
   TimeToStruct(time_current,STime);

   int currentDayOfWeek = STime.day_of_week;

// Check the selected trading days
   switch(currentDayOfWeek)
     {
      case 0: // Sunday
         return ExtTradeOnSunday;
      case 1: // Monday
         return ExtTradeOnMonday;
      case 2: // Tuesday
         return ExtTradeOnTuesday;
      case 3: // Wednesday
         return ExtTradeOnWednesday;
      case 4: // Thursday
         return ExtTradeOnThursday;
      case 5: // Friday
         return ExtTradeOnFriday;
      case 6: // Saturday
         return ExtTradeOnSaturday;
      default:
         return false; // Error, not a valid day of the week
     }
  }
//+------------------------------------------------------------------+
bool IsTradingTime()
  {
   MqlDateTime STime;
   datetime time_current=(TimeTradeServer());
   TimeToStruct(time_current,STime);
   int currentDayOfWeek = STime.day_of_week;
// Check the selected trading days
   switch(currentDayOfWeek)
     {
      case 0: // Sunday
         return (time_current>=StringToTime(SundayStartTime) && time_current<=StringToTime(SundayStopTime));
      case 1: // Monday
         return (time_current>=StringToTime(MondayStartTime) && time_current<=StringToTime(MondayStopTime));
      case 2: // Tuesday
         return (time_current>=StringToTime(TuesdayStartTime) && time_current<=StringToTime(TuesdayStopTime));
      case 3: // Wednesday
         return (time_current>=StringToTime(WednesdayStartTime) && time_current<=StringToTime(WednesdayStopTime));
      case 4: // Thursday
         return (time_current>=StringToTime(ThursdayStartTime) && time_current<=StringToTime(ThursdayStopTime));
      case 5: // Friday
         return (time_current>=StringToTime(FridayStartTime) && time_current<=StringToTime(FridayStopTime));
      case 6: // Saturday
         return (time_current>=StringToTime(SaturdayStartTime) && time_current<=StringToTime(SaturdayStopTime));
      default:
         return false; // Error, not a valid day of the week
     }
  }
//+---------------------------------------------------------------------------+
//|                          MOVE TO BREAK EVEN                               |
//+---------------------------------------------------------------------------+
void BreakEven()
  {

   int positions_total = PositionsTotal();
   for(int i = positions_total - 1; i >= 0; i--)  // Going backwards in case one or more positions are closed during the cycle.
     {
      ulong ticket = PositionGetTicket(i);
      if(m_position.SelectByIndex(i))
         if(ticket <= 0)
           {
            Print("ERROR - Unable to select the position - ", GetLastError());
            continue;
           }

      if(PositionGetDouble(POSITION_PROFIT) <= 0)
         continue; // Unprofitable positions are always skipped.
      double point = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_POINT);
      if(SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED)
        {
         Print("Trading is disabled for ", PositionGetString(POSITION_SYMBOL), ". Skipping.");
         continue;
        }

      double extra_be_distance = AdditionalProfit * point;
      int digits = (int)SymbolInfoInteger(PositionGetString(POSITION_SYMBOL), SYMBOL_DIGITS);
      double tick_size = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_TRADE_TICK_SIZE);
      if(tick_size > 0)
        {
         // Adjust for tick size granularity.
         extra_be_distance = NormalizeDouble(MathRound(extra_be_distance / tick_size) * tick_size, digits);
        }
      else
        {
         Print("Zero tick size for ", PositionGetString(POSITION_SYMBOL), ". Skipping.");
         continue;
        }

      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
         double BE_price = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN) + extra_be_distance, digits);
         if((SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_BID) >= BE_price) && (BE_price > PositionGetDouble(POSITION_SL)))  // Only move to BE if the price is above the calculated BE price, and the current stop-loss is lower.
           {
            double prev_sl = PositionGetDouble(POSITION_SL); // Remember old SL for reporting.
            // Write BE price to the SL field.
            if(!m_trade.PositionModify(ticket, BE_price, PositionGetDouble(POSITION_TP)))
               Print("PositionModify Buy BE failed ", GetLastError(),  " for ", PositionGetString(POSITION_SYMBOL));
            else
               Print("Breakeven was applied to position - " + PositionGetString(POSITION_SYMBOL) + " BUY #" + IntegerToString(ticket) + " Lotsize = ", PositionGetDouble(POSITION_VOLUME), ", OpenPrice = " + DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), digits) + ", Stop-Loss was moved from " + DoubleToString(prev_sl, digits) + ".");
           }
        }
      else
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
           {
            double BE_price = NormalizeDouble(PositionGetDouble(POSITION_PRICE_OPEN) - extra_be_distance, digits);
            if((SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_ASK) <= BE_price) && ((BE_price < PositionGetDouble(POSITION_SL)) || (PositionGetDouble(POSITION_SL) == 0)))   // Only move to BE if the price below the calculated BE price, and the current stop-loss is higher (or zero).
              {
               double prev_sl = PositionGetDouble(POSITION_SL); // Remember old SL for reporting.
               // Write BE price to the SL field.
               if(!m_trade.PositionModify(ticket, BE_price, PositionGetDouble(POSITION_TP)))
                  Print("PositionModify Buy BE failed ", GetLastError(),  " for ", PositionGetString(POSITION_SYMBOL));
               else
                  Print("Breakeven was applied to position - " + PositionGetString(POSITION_SYMBOL) + " SELL #" + IntegerToString(ticket) + " Lotsize = ", PositionGetDouble(POSITION_VOLUME), ", OpenPrice = " + DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), digits) + ", Stop-Loss was moved from " + DoubleToString(prev_sl, digits) + ".");
              }
           }
     }
   return;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
