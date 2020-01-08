//+------------------------------------------------------------------+
//|                                                   CSV_export.mq4 |
//| Calculate a CSV with the given variables, indicators or training
//| signals.
//| This version only has an ema 15 of HLC/3 for denoising and HLC/3  as noisy signal
//+------------------------------------------------------------------+
#property copyright "Harvey D. Bastidas C."
#property link      "https://github.com/harveybc" 
#property version   "0.1"
#property strict
#property script_show_inputs
// #include <WaveEncoding.mqh>
//+------------------------------------------------------------------+
// script input parameters
//+------------------------------------------------------------------+
//0 = HighBid, 1 = Low, 2 = Close, 3 = NextOpen, 4 = v, 5 = MoY, 6 = DoM, 7 = DoW, 8 = HoD, 9 = MoH, ..<num_co
input string   filename="eh1_2015_2018_70.csv";   // output filename
input string   symbol="EURUSD"; // symbol , usar EURUSD, un top 5(YEN?) y un top 10(OTRO)
input int      tf_base=PERIOD_H1;    // base period
input int      indicator_period=10;   //  period for all indicator calculations 14
input int      short_multiplier=2; // Multiplier for the mid-term  (uses 1/short_multiplier) 
input int      long_multiplier=2; // Multiplier for the long-term 
input datetime date_start=D'2014.12.13 00:00'; // start date of the exported indicators
input datetime date_end=D'2018.12.13 23:59';   // end date of the exported indicators
input bool     use_return=false; // export return values=(Vf-Vi)/Vi
input bool     use_return_indicators=false; // exports returns for indicators
input bool     use_return_volume=false; // exports returns for volume
input bool     use_return_candle=false; // exports returns for candles
input int      train_signal=0;  // 0= No training signal, 1=H,2=L,3=C,4=H-L, 5=(C-L)/(H-L),6=(C-O)/(H-L)
input bool     hlc=true; // export High,Low, And Close for price
input bool     volumen=true; //export the volume
input bool     candle=true; // export (H-L),(C-L)/(H-L) y (C-O)/(H-L)
input bool     indicators=true; // The RSI, MACD, and CCI indicators 
input bool     time_signals=true; // HoD=Hour of Day,DoW=DayOfWeek,WoM,WoQ=WeekOfQuarter,QoY=QuarterOfYear,MoY
input bool     sml_tf=true; // short and long timeframes
input string   newc=","; // separador de columnas de CSV
input string   newl="\n"; // separador de nueva fila en CSV
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   int handle;
// open file with write access
   handle=FileOpen(filename,FILE_BIN|FILE_WRITE);
// check for error
   if(handle==INVALID_HANDLE)
     {
      Print("OnStart: Can't open file -",GetLastError());
      return;
     }
// write values to the array
   WriteCSV(handle);
// close file
   FileClose(handle);

  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
string non_returned(int i,bool &sep_flag)
  {
// para fila de CSV
   double denom;// for division by zero watch
   string text="";
// genera hlc, columns 0,1,2
   if(hlc)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;       
      text=StringConcatenate(text,DoubleToStr(iHigh(symbol,tf_base,i),8)+newc+DoubleToStr(iLow(symbol,tf_base,i),8)+newc+DoubleToStr(iClose(symbol,tf_base,i),8));
     }
//volumen , column 3
   if(volumen)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;
      text=StringConcatenate(text,DoubleToStr(iVolume(symbol,tf_base,i),8));
     }
// genera tech indicators , columns 4:RSI,5:MACD,6:ADX,7:CCI,8:ATR,9:Stochastic, 10 EMA
// short term: 11:RSI, 12:MACD, 13:ADX, 14:CCI, 15:ATR, 16:Stochastic, 17:EMA short term
// long term: 18:RSI, 19:MACD, 20:ADX, 21:CCI, 22:ATR, 23:Stochastic, 24:EMA long term
   if(indicators)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;
      // generate multi-timeframe data for the allowed indicators
      for(int k=0;k<3;k++){

         // mid-term indicators (always calculated)
         int ip = indicator_period;
         // short term indicators
         if (k==1){
            ip = indicator_period / short_multiplier;
         }
         // long term indicators
         if (k==2){
            ip = indicator_period * long_multiplier;
         }
         // calculate the values of indicators
         if ((k==0) || (sml_tf)){
            text=StringConcatenate(text, DoubleToStr(iRSI(symbol,tf_base,ip/2,PRICE_WEIGHTED,i),8)+newc);
            text=StringConcatenate(text, DoubleToStr(iMACD(symbol,tf_base,ip,ip*2,9,PRICE_WEIGHTED,MODE_MAIN,i),8)+newc);
            text=StringConcatenate(text, DoubleToStr(iADX(symbol,tf_base,ip,PRICE_WEIGHTED,MODE_MAIN,i),8)+newc);
            text=StringConcatenate(text, DoubleToStr(iCCI(symbol,tf_base,ip,PRICE_WEIGHTED,i),8)+newc);
            text=StringConcatenate(text, DoubleToStr(iATR(symbol,tf_base,ip,i),8)+newc);
            text=StringConcatenate(text, DoubleToStr(iStochastic(symbol,tf_base,ip,(int)MathFloor(ip*0.6f),(int)MathFloor(ip*0.6f),MODE_EMA,0, MODE_SIGNAL,i),8)+newc);
            text=StringConcatenate(text, DoubleToStr(iMA(symbol,tf_base,ip,0,MODE_EMA,PRICE_WEIGHTED,i),8)+newc);
         }
      }
      // column 25: adds other indicators that cant be generated in multi-timeframe (with standard mql4 functions)
      text=StringConcatenate(text, DoubleToStr(iOBV(symbol,tf_base,PRICE_WEIGHTED,i),8));
         
     }
     // genera candles, columns 26,27,28
   if(candle)
     {
      if(sep_flag) text=StringConcatenate(text,newc);
      sep_flag=true;
      text=StringConcatenate(text, DoubleToStr(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i),8)+newc);
      text=StringConcatenate(text, DoubleToStr((iClose(symbol,tf_base,i)-iLow(symbol,tf_base,i))/(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i)),8)+newc);
      text=StringConcatenate(text, DoubleToStr((iClose(symbol,tf_base,i)-iOpen(symbol,tf_base,i))/(iHigh(symbol,tf_base,i)-iLow(symbol,tf_base,i)),8));
     }
   return text;
  }
//+------------------------------------------------------------------+
//| WriteCSV                                   |
//+------------------------------------------------------------------+
void WriteCSV(int handle)
  {
// obtiene en candlestick index de inicio(mayor index) y fin (menor index)
   int ini_candle=iBarShift(symbol,tf_base,date_start,false);
   int end_candle=iBarShift(symbol,tf_base,date_end,false);
   if((ini_candle==-1) || (end_candle==-1))
     {
      Print("Error, tf_base_=",tf_base,",date_start_=",date_start,", candle_ini=",ini_candle,"candle_end=",end_candle,"  for symbol ",symbol," not found. 2");
     }
   Print("tf_base=",tf_base,",date_start=",date_start,", candle_ini=",ini_candle,"candle_end=",end_candle,"  for symbol ",symbol);
// para i desde inicio hasta fin,
   string text="";
   for(int i=ini_candle; i>=end_candle;i--)
     {
      // flag para indicar si debe prrfijar un newc separator antes del prox valor
      bool sep_flag=false;
      text="";
      text=StringConcatenate(text,non_returned(i,sep_flag));
      // genera time_signals HoD=Hour of Day,DoW=DayOfWeek,DoM,DoY,MoY
      // cols: 25,26,27,28
      if(time_signals)
        {
         if(sep_flag) text=StringConcatenate(text,newc);
         sep_flag=true;
         datetime i_time=iTime(symbol,tf_base,i);
         //text=StringConcatenate(text, IntegerToString(TimeMonth(i_time))+newc);
         text=StringConcatenate(text, IntegerToString(TimeDay(i_time))+newc);       // 25
         text=StringConcatenate(text, IntegerToString(TimeDayOfWeek(i_time))+newc); // 26
         text=StringConcatenate(text, IntegerToString(TimeHour(i_time))+newc);      // 27
         text=StringConcatenate(text,IntegerToString(TimeMinute(i_time)));          // 28
        }
      // si i!=fin, escribe newl
      if(i!=end_candle)
        {
         text=StringConcatenate(text,newl);
        }
      FileWriteString(handle,text);
     }
  }
//+------------------------------------------------------------------+
