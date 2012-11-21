package mfcc.MFCC {
	import flash.utils.ByteArray;
	import org.as3wavsound.sazameki.core.AudioSamples;
	import org.as3wavsound.sazameki.format.wav.Wav; 
	import org.as3fft.FFT2;
	import org.as3fft.ComplexNumber;
	import mfcc.filterbank.Filterbank;
	import mfcc.filterbank.Filter;
	
	public class MFCC {
	
		private static const PREEMCOEF:Number = 0.97;
		private static const SAMPLERATE:Number = 8000;
		private static const N:int = 256;// samples per window

		public function MFCC(wavData:ByteArray) {
			var bytesTotal:Number = wavData.length;
			trace("recording bytes " + bytesTotal);
			var audioSamples:AudioSamples = new Wav().decode(wavData);
			var samples:Vector.<Number> = audioSamples.left; 
			preEmphasis(samples);

			// pre-render the hamming window
			var hamming: Vector.<Number> =   new Vector.<Number>(256); 
			populateHammingWindow(hamming);

			// get each frame and perform a series of tasks

			// prepare the vectors
			var xRe:Vector.<Number> = new Vector.<Number>(N);
			var xIm:Vector.<Number> = new Vector.<Number>(N);
			
			// prepare filterbank
			var filterbank:Filterbank = new Filterbank();
			
			for (var i:int=0; i<1; i++) { // only 1 frame for now
				// copy the ones in the window
				for (var j:int=0; j<N; j++) {
					xRe[j] = samples[N*i + j];
				}
				// hamming
				for (j=0; j<N; j++) {
					xRe[j] *= hamming[j];  
				}				
				// FFT object
				var fft:FFT2 = new FFT2();
				var logN:Number = Math.log(N)*Math.LOG2E
				fft.init(logN);
				fft.run(xRe, xIm);
				// get mag of each c number
				var xMag:Vector.<Number> = new Vector.<Number>(N);
				for(j=0; j<N; j++) {
					var c:ComplexNumber = new ComplexNumber(xRe[j], xIm[j]);
					xMag[j] = c.magnitude;
				}
				var result:Number = 0.0;
				// filterbank
				var melspec:Vector.<Number> = filterbank.melspec(xMag, SAMPLERATE/N);
				trace("after applied filterbank " + melspec);
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