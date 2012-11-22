package mfcc.MFCC {
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mfcc.filterbank.Filter;
	import mfcc.filterbank.Filterbank;
	
	import org.as3fft.ComplexNumber;
	import org.as3fft.FFT2;
	import org.as3wavsound.sazameki.core.AudioSamples;
	import org.as3wavsound.sazameki.format.wav.Wav;
	
	
	public class MFCC39 {
	
		private static const PREEMCOEF:Number = 0.97;
		private static const SAMPLERATE:Number = 8000;
		private static const N:int = 256;// samples per window
		
		private var _hamming: Vector.<Number>;
		private var _filterbank:Filterbank;

		public function MFCC39() {
			// pre-render the hamming window
			_hamming =   new Vector.<Number>(256); 
			populateHammingWindow(_hamming);
	
			// prepare filterbank
			var urlLoader:URLLoader = new URLLoader();
			urlLoader.load(new URLRequest('asciiC.txt'));
			urlLoader.addEventListener(Event.COMPLETE, loadFilterbank);
		}
		
		private function loadFilterbank(e:Event):void {
			var cArray:Array = e.target.data.split(/ /);
			_filterbank = new Filterbank(cArray);
		}

		public function extract(wavData:ByteArray):void {
			var bytesTotal:Number = wavData.length;
			trace("recording bytes " + bytesTotal);
			var audioSamples:AudioSamples = new Wav().decode(wavData);
			var samples:Vector.<Number> = audioSamples.left; 
			preEmphasis(samples);
			// get each frame and perform a series of tasks
			
			// prepare the vectors
			var xRe:Vector.<Number> = new Vector.<Number>(N);
			var xIm:Vector.<Number> = new Vector.<Number>(N);
			
			for (var i:int=0; i<1; i++) { // only 1 frame for now
				// copy the ones in the window
				for (var j:int=0; j<N; j++) {
					xRe[j] = samples[N*i + j];
				}
				// hamming
				for (j=0; j<N; j++) {
					xRe[j] *= _hamming[j];  
				}				
				// FFT object
				var fft:FFT2 = new FFT2();
				var logN:Number = Math.log(N)*Math.LOG2E
				fft.init(logN);
				fft.run(xRe, xIm);
				// get mag of each c number
				var xMag:Vector.<Number> = new Vector.<Number>(N/2);
				for(j=0; j<N/2; j++) {
					var c:ComplexNumber = new ComplexNumber(xRe[j], xIm[j]);
					xMag[j] = c.magnitude;
				}
				trace("xMag length: ", xMag.length);
				var m:Vector.<Number> = _filterbank.melspec(xMag, SAMPLERATE/N);
				trace("after applied filterbank " + m);
				// what's the next step
			}
		}
		
		private function preEmphasis(samples:Vector.<Number>):void {
			for (var i:int=samples.length - 1; i>0; i--) {
				samples[i] = samples[i] - PREEMCOEF*samples[i-1];
			}
		}
		
// Helpers		
		private function populateHammingWindow(hamming:Vector.<Number>):void {
			for(var i:uint=0; i<N; i++) {
				// same as iOS library
				hamming[i] = 0.54 - 0.46 * Math.cos(2.0*Math.PI*i/N);
			}
		}

		private function debugLog(samples:Vector.<Number>, fromIndex:uint, length:uint):void {
			for(var i:uint= fromIndex; i< fromIndex+ length; i++) {
				trace(samples[i]);
			}
		}
	} 	
}