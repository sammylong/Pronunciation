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
		private static const SHIFT:int = 80; // samples per shift
		private static const NUMCEPTS:int = 12;
		
		private var _hamming: Vector.<Number>;
		private var _filterbank:Filterbank;

		public function MFCC39() {
			// pre-render the hamming window
			_hamming =   new Vector.<Number>(N); 
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
			// debug
			preEmphasis(samples);

			// get each frame and perform a series of tasks
			trace("samples length: ", samples.length);

			var numFrames:uint = Math.floor(((samples.length as Number) - N)/SHIFT) as uint;
			trace("num frames: ", numFrames);
			//debug
			numFrames = 20;
			
			// prepare the vectors
			var xRe:Vector.<Number> = new Vector.<Number>(N);
			var xIm:Vector.<Number> = new Vector.<Number>(N);
			
			for (var i:uint=0; i<numFrames; i++) { // only x frames for now
				// coyp the ones in the window
				
				// todo: find out zeros
				for (var j:int=0; j<N; j++) {
					xRe[j] = samples[SHIFT*i + j];
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
				var m:Vector.<Number> = _filterbank.melspec(xMag, SAMPLERATE/N);
				trace(i + " m " + m);
				// log
				for (j=0; j<NUMCEPTS; j++) {
					m[j] = Math.log(m[j]);
				}
				var cc:Vector.<Number> = new Vector.<Number>(NUMCEPTS);
				// dct
				var numChans:Number = _filterbank.numChans as Number; 
				for (j=0; j<NUMCEPTS; j++) {
					var sum:Number = 0.0;
					for (var k:int=0; k<numChans; k++) {
						sum+= m[k]*Math.cos(Math.PI*j/numChans*(k-0.5));
					}
					cc[j] = Math.sqrt(2.0/numChans)*sum;
				}
				trace(i + " mfcc " + cc);
				//

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