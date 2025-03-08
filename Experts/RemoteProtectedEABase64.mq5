//+------------------------------------------------------------------+
//|                                      RemoteProtectedEABase64.mq5 |
//|                                      Copyright 2012, Investeo.pl |
//|                                           http://www.investeo.pl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Investeo.pl"
#property link      "http://www.investeo.pl"
#property version   "1.00"

#include <MQL5-RPC.mqh>
#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayInt.mqh>
#include <Arrays\ArrayString.mqh>
#include <Arrays\ArrayBool.mqh>
#include <Base64.mqh>

bool license_status=false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
/* License proxy server */
   CXMLRPCServerProxy s("192.168.2.103:9099");

   if(s.isConnected()==true)
     {
      CXMLRPCResult *result;

/* Get account data */
      string broker= AccountInfoString(ACCOUNT_COMPANY);
      long account = AccountInfoInteger(ACCOUNT_LOGIN);

      printf("The name of the broker = %s",broker);
      printf("Account number =  %d",account);

/* Get remote license status */
      CArrayObj* params= new CArrayObj;
      CArrayString* ea = new CArrayString;
      CArrayString* br = new CArrayString;
      CArrayInt *ac=new CArrayInt;

      ea.Add("RemoteProtectedEA");
      br.Add(broker);
      ac.Add((int)account);

      params.Add(ea); params.Add(br); params.Add(ac);

      CXMLRPCQuery query("isValid",params);

      result=s.execute(query);

      CArrayObj *resultArray=result.getResults();
      if(resultArray!=NULL && resultArray.At(0).Type()==TYPE_STRING)
        {
         CArrayString *stats=resultArray.At(0);

         string license_encoded=stats.At(0);

         printf("encoded license: %s",license_encoded);

         string license_decoded;

         Base64Decode(license_encoded,license_decoded);

         printf("decoded license: %s",license_decoded);

         CXMLRPCResult license(license_decoded);
         resultArray=license.getResults();

         CArrayBool *bstats=resultArray.At(0);

         license_status=bstats.At(0);
        }
      else license_status=false;

      if(license_status==true) printf("License valid.");
      else printf("License invalid.");

      delete params;
      delete result;
     }
   else Print("License server not connected.");

//---
   return(0);
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
//---
   if(license_status==true)
     {
      // license valid
     }
  }
//+------------------------------------------------------------------+
