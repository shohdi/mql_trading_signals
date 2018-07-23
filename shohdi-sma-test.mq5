//+------------------------------------------------------------------+
//|                                                  TradeByTick.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, shohdy elshemy"
#property link      ""
#property version   "1.00"






//+------------------------------------------------------------------+
//| My custom types                                   |
//+------------------------------------------------------------------+

enum SmaCalcType
{
   Close = 0
   ,High = 1
   ,Low = 2
   ,Mid = 3
};


struct MqlCandle
 {
   double Close;
   double Open;
    int Dir;
   double High;
    double Low;
    double Volume;
    datetime Date;
 };
 

 
MqlTick currentTick;
MqlTick lastTick;
MqlCandle lastCandle;
 
 
  
//+------------------------------------------------------------------+
//| variables needed                                   |
//+------------------------------------------------------------------+


input int noOfTradePeriods = 8;


input int shortPeriod = 14;
input int longPeriod = 28;
input int periodsToCheck = 5;
input double riskToProfit = 2;









int noOfSuccess = 0;
int noOfFail = 0;





//+------------------------------------------------------------------+
//| My custom functions                                   |
//+------------------------------------------------------------------+



bool calcTime()
{
    //datetime currentDate = TimeCurrent();
        
    //      MqlDateTime strucTime;
    //      TimeToStruct(currentDate,strucTime);
          
    //      return (strucTime.hour >= startHour && strucTime.hour <= endHour);
    
    return true;
}


MqlCandle getCandle (int pos)
 {
      MqlCandle ret;
      
      double closes[1];
      double opens[1];
      double highs[1];
      double lows[1];
      long volumes[1];
       datetime dates[1];
      CopyClose(_Symbol,_Period,pos,1,closes);
       CopyOpen(_Symbol,_Period,pos,1,opens);
      CopyHigh(_Symbol,_Period,pos,1,highs);
      CopyLow(_Symbol,_Period,pos,1,lows);
      CopyTime(_Symbol,_Period,pos,1,dates);
      ret.Volume = 1;
      int volFound = CopyRealVolume(_Symbol,_Period,pos,1,volumes);
      if(volFound <= 0)
      {
        volFound =  CopyTickVolume(_Symbol,_Period,pos,1,volumes);
      
      }
      
      
       if(volumes[0] > 0)
         {
               ret.Volume = volumes[0];
         }
      
      ret.Date = dates[0];
      ret.Close = closes[0];
      ret.Open = opens[0];
      ret.High = highs[0];
      ret.Low = lows[0];
      if(ret.Open < ret.Close)
         ret.Dir = 1;
     else if (ret.Open > ret.Close)
         ret.Dir = -1;
     else
         ret.Dir = 0;
         
         
         return ret;
         
            
 }
 
 

 


double compareCandles (MqlCandle &old,MqlCandle &newC)
{
      if (newC.High > old.High
      && newC.Close > old.Close
      && newC.Low > old.Low)
      {
         return 1;
      }
      else if (newC.High < old.High
      && newC.Close < old.Close
      && newC.Low < old.Low)
      {
         return -1;
      }
      else
      {
         return 0;
      }
      
}


double getDirectionOfNoOfPeriods (int pos,int noOfPeriods)
{
      MqlCandle lastCandle = getCandle(pos);
      MqlCandle startCandle = getCandle(pos+(noOfPeriods));
      if(startCandle.Close > lastCandle.Close)
      {
         return -1;
      }
      else if (startCandle.Close < lastCandle.Close)
      {
         return 1;
      }
      else
      {
         return 0;
      }
}






double shohdiSma (int pos,int periods,SmaCalcType type)
{
       
     string arrayPrint = " Priods : " + periods;
       double vals[];
       double high[];
       double low[];
       
       ArrayResize(vals,periods);
 ArrayResize(high,periods);
  ArrayResize(low,periods);
      
       if(type == 0)
       {
            CopyClose(_Symbol,_Period,pos,periods,vals);
            
       }
       else if(type == 1)
       {
         CopyHigh(_Symbol,_Period,pos,periods,vals);
       }
       else if (type == 2)
       {
         CopyLow(_Symbol,_Period,pos,periods,vals);
       }
       else
       {
            
             CopyHigh(_Symbol,_Period,pos,periods,high);
              CopyLow(_Symbol,_Period,pos,periods,low);
             
              for (int i=0;i<periods;i++)
              {
                  
                  vals[i] = (high[i] + low[i])/2;
                  arrayPrint = arrayPrint + " index : "+i +  " high : " + high[i] + " low : " + low[i] + " mid : " + vals[i] ;
              }
              
              
              
              
       }
       
       
       double sum = 0;
       for (int j=0;j<periods;j++)
       {
              sum = sum + vals[j];      
       }
       
       
       double result = sum / ((double)periods);
       arrayPrint =arrayPrint + " sum : " + sum + " result : " + result;
       //Print (arrayPrint);
      
       return result;
}







string printDir (double value)
{
      if(value == 0)
         return "equal";
     
     if(value > 0)
         return "green";
         
      if(value < 0)
            return "red";
            
            
            return "equal";
}





double shohdiSignalDetect (int pos)
{

      int myPos = pos ;
      int beforePos = myPos + 1;
      double lastShortSma = shohdiSma(myPos,shortPeriod,0);
      double lastLongSma = shohdiSma(myPos,longPeriod,0);
      double beforeShortSma = shohdiSma(beforePos,shortPeriod,0);
      double beforeLongSma = shohdiSma(beforePos,longPeriod,0); 
      if(lastShortSma < lastLongSma  && beforeShortSma > beforeLongSma)
      {
         return -1;
      }
      else if  (lastShortSma > lastLongSma  && beforeShortSma < beforeLongSma)
      {
         return 1;
      }
      else
      {
         return 0;
      }
          
      
       
    
}


void shohdiCalculateSuccessFail ()
{
        double signal = shohdiSignalDetect(1 + (noOfTradePeriods * periodsToCheck));
        double averageMove = calculateMoveOfStopLoss(1 + (noOfTradePeriods * periodsToCheck)) / riskToProfit;
        int lastPos = 1 + (noOfTradePeriods * periodsToCheck);
        
        if(signal >0)
        {
            //up
            Print("found up");
            calculateSuccessFailUp(signal,averageMove,lastPos);
            
            
        }
        else if(signal < 0)
        {
            //down
            Print("found down");
            calculateSuccessFailDown(signal,averageMove,lastPos);
        }
        else
        {
        }
        
        
               
}


void calculateSuccessFailUp(double signal,double averageMove,int lastPos)
{
   MqlCandle lastCandle = getCandle(lastPos);
   double stopLoss = lastCandle.Close - averageMove;
   double takeProfit = lastCandle.Close + (averageMove * riskToProfit);
   double highs[];
   double lows[];
   int countToCheck = lastPos-1;
   ArrayResize(highs,countToCheck);
   ArrayResize(lows,countToCheck);
   
   CopyHigh(_Symbol,_Period,1,countToCheck,highs);
   CopyLow(_Symbol,_Period,1,countToCheck,lows);
   
   bool foundResult = false;
   for (int i=0;i<countToCheck;i++)
   {
      if(!foundResult)
      {
         if(lows[i] <= stopLoss)
         {
            //fail
            noOfFail++;
            foundResult = true;
         }
         else if(highs[i] >= takeProfit)
         {
            //success
            noOfSuccess++;
            foundResult = true;
         }
      }
      
   }
   
   
   
   if(!foundResult)
      noOfFail++;
   
   
   
   
   
}

void calculateSuccessFailDown(double signal,double averageMove,int lastPos)
{

    MqlCandle lastCandle = getCandle(lastPos);
   double stopLoss = lastCandle.Close + averageMove;
   double takeProfit = lastCandle.Close - (averageMove * riskToProfit);
   double highs[];
   double lows[];
   int countToCheck = lastPos-1;
   ArrayResize(highs,countToCheck);
   ArrayResize(lows,countToCheck);
   
   CopyHigh(_Symbol,_Period,1,countToCheck,highs);
   CopyLow(_Symbol,_Period,1,countToCheck,lows);
   
   bool foundResult = false;
   for (int i=0;i<countToCheck;i++)
   {
      if(!foundResult)
      {
         if(highs[i] >= stopLoss)
         {
            //fail
            noOfFail++;
            foundResult = true;
         }
         else if(lows[i] <= takeProfit)
         {
            //success
            noOfSuccess++;
            foundResult = true;
         }
      }
      
   }
   
   if(!foundResult)
      noOfFail++;

}

double calculateMoveOfStopLoss(int pos)
{
  double highs[];
  double lows[];
  
  ArrayResize(highs,longPeriod);
  ArrayResize(lows,longPeriod);
  
  int bars = noOfTradePeriods - 1;

   CopyHigh(_Symbol,_Period,pos,longPeriod,highs);
   CopyLow(_Symbol,_Period,pos,longPeriod,lows);
   
   double average = 0;
   int count = 0;
   for (int i=0;(i+bars) < longPeriod;i+=noOfTradePeriods)
   {
      double allHigh = 0;
      double allLow = 999999999;
      for (int j=0;j<noOfTradePeriods;j++)
      {
         int index = i+j;
         if(allHigh < highs[index])
            allHigh = highs[index];
         
         if(allLow > lows[index])
            allLow = lows[index];
         
      }
      
      double moveMent = allHigh - allLow;
      average = average + moveMent;
      count = count + 1;
      
   }
   
   average = average / count;
   
   average = average - (average * 0.25);
   
   return average;
  
}





//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(1);
      lastTick.ask = -1 ;
      lastTick.bid = -1;
      currentTick.ask = -1;
      currentTick.bid = -1;
      lastCandle.Close = -1;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
       Print("no of success : " + noOfSuccess + " , no of fail : " + noOfFail);
        double totalVal = noOfSuccess + noOfFail;
        if(totalVal > 0)
        {
            Print("Percentage : " + ((noOfSuccess/totalVal)* 100));
            
        }
   
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- 
        // SymbolInfoTick(_Symbol,currentTick);
         
         //Print("new Tick" + currentTick.time);
         MqlCandle currentCandle = getCandle(0);
         
         
         if(lastCandle.Close == -1)
         {
            lastCandle = currentCandle;
            return;
         }
         
         if(currentCandle.Date != lastCandle.Date)
         {
            //new candle , do work here
           
           
            shohdiCalculateSuccessFail();
            
            
           
            
            
           
           
          
            
         }
         
         
          lastCandle = currentCandle;
        
         
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {

   
          
          
   
  }
//+------------------------------------------------------------------+
