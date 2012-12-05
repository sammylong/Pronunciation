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
		private static const SAMPLERATE:Number = 8000;//8000;
		private static const N:int = 256;// samples per window
		private static const SHIFT:int = 80; // samples per shift
		private static const NUMCHANS:int = 26;
		private static const NUMCEPS:int = 12;
		private static const CEPLIFTER:int = 22;
		private static const MFCCDIM:int = 39;
		
		private var _hamming: Vector.<Number>;
		private var _filterbank:Filterbank;

		public function MFCC39() {
			// pre-render the hamming window
			_hamming = genHammingWindow();
			_filterbank = new Filterbank(NUMCHANS, SAMPLERATE, N);
		}

		public function extract(wavData:ByteArray):void {
			var bytesTotal:Number = wavData.length;
			trace("recording bytes " + bytesTotal);
			var audioSamples:AudioSamples = new Wav().decode(wavData);
			var numFrames:int = Math.ceil(((audioSamples.length as Number) - N)/SHIFT) as int;
			trace("init num frames: ", numFrames);
			var samples:Vector.<Number> = new Vector.<Number>((numFrames - 1)*SHIFT + N); 
			for (var l:int=0; l<audioSamples.length; l++) {
				samples[l] = audioSamples.left[l];
			}
			// get each frame and perform a series of tasks
			trace("samples length: ", samples.length);
			// prepare the vectors
			var xRe:Vector.<Number> = new Vector.<Number>(N);
			var xIm:Vector.<Number> = new Vector.<Number>(N);
/*
			// fft test
			for (var j:int=0; j<N; j++) {
				xRe[j] = j+1;
				xIm[j] = 0.0;
			}
			var fftTest:FFT2 = new FFT2();
			fftTest.init(8);
			fftTest.run(xRe, xIm);
			
			for (j=0; j<N/2; j++) {
				trace("j: " + j + " Re: " + xRe[j] + " Im: " + xIm[j]);
			}	
*/
			
			var features:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(numFrames);
			for (var i:int=0; i< numFrames; i++) { // only x frames for now
				// coyp the ones in the window				
				for (var j:int=0; j<N; j++) {
					xRe[j] = samples[SHIFT*i + j];
					xIm[j] = 0.0;
				}
				//preEmphasis
				preEmphasis(xRe);

				// hamming
				for (j=0; j<N; j++) {
					xRe[j] *= _hamming[j];  
				}			

				// FFT object
				var fft:FFT2 = new FFT2();
				var logN:Number = Math.log(N)*Math.LOG2E;
				fft.init(logN);
				fft.run(xRe, xIm);
/*	
				for (j=0; j<N/2; j++) {
					trace(j + ": Re: " + xRe[j] + " Im: " + xIm[j]);
				}
*/
				// get mag of each c number
				var xMag:Vector.<Number> = new Vector.<Number>(N/2);
				for(j=0; j<N/2; j++) {
					xMag[j] = Math.sqrt(Math.pow(xRe[j], 2) + Math.pow(xIm[j], 2));
					//trace(i + ", " + j + ": " + xMag[j]);
				}
				var m:Vector.<Number> = _filterbank.melspec(xMag);

				// cepstral coefs container
				var cc:Vector.<Number> = new Vector.<Number>(MFCCDIM);
				computeCepstralCoef(m, cc);
				// ceptstral lifter
				cepstralLifter(cc);
				//trace(i + " : " + cc);

/*
				for (j=0; j<NUMCEPS; j++) {
					trace(i + " , " + j + " : " + cc[j] );
				}
*/
				features[i] = cc;
			}
					
			// regression first order
			var denominator:Number = 0.0;
			for (var t:int=1; t<=2; t++) {
				denominator += t*t;
			}
			denominator *= 2.0;
			for (i=0; i< numFrames; i++) {
				for (j=0; j< NUMCEPS; j++) {
					var prev:int = i;
					var next:int = i;
					var sum:Number = 0.0;
					for (t=1; t<=2; t++) {
						if (i + t < numFrames) next++;
						if (i - t >=0) prev--;
						var nextFeature:Vector.<Number> = features[next];
						var prevFeature:Vector.<Number> = features[prev];
						sum += t*(nextFeature[j] - prevFeature[j]);
					}
					sum /= denominator;
					var feature:Vector.<Number> = features[i];
					feature[j + NUMCEPS + 1] = sum;
				}
			}
	
/*
			// container for average value
			var avgCoefs:Vector.<Number> = new Vector.<Number>(NUMCEPS);
			// zero it all
			for each (var num:Number in avgCoefs) {
				num = 0.0;
			}


			// compute average
			for each (var f:Vector.<Number> in features) {
				for (var k:uint=0; k<f.length; k++) {
					avgCoefs[k]+=f[k]/features.length;// could be precision problem
				}
			}

			trace("average: " + avgCoefs);
			// subtract average
			for each (f in features) {
				for (k=0; k<f.length; k++) {
					f[k] -= avgCoefs[k];
				}
			}
*/
			

			// debug print
			for (j=191; j<numFrames;j++) {
				trace(j + ": " + features[j]);
			}
		}
		private function preEmphasis(samples:Vector.<Number>):void {
			for (var i:int=samples.length - 1; i>0; i--) {
				samples[i] -= PREEMCOEF*samples[i-1];
			}
			samples[0] *= (1.0 - PREEMCOEF);
		}
		private function genHammingWindow():Vector.<Number> {
			var hamming:Vector.<Number>  = new Vector.<Number>(N);
			for(var i:int=0; i<hamming.length; i++) {
				// same as iOS library
				hamming[i] = 0.54 - 0.46 * Math.cos(2.0*Math.PI*i/(N-1));
			}
			return hamming;
		}
		private function computeCepstralCoef(m:Vector.<Number>, cc:Vector.<Number>):void {
			var numChans:Number = m.length as Number; 
			for (var j:int=0; j<NUMCEPS; j++) {
				cc[j] = 0.0;
				for (var k:int=0; k<numChans; k++) {
					var factor:Number = Math.cos((Math.PI*(j+1)/numChans)*((k+1)-0.5));
					cc[j]+= Math.sqrt(2.0/numChans)*m[k]*factor;
				}
			}
		}
		private function cepstralLifter(cc:Vector.<Number>):void {
			for (var j:int=0; j<NUMCEPS; j++) {
				cc[j] *= 1 + 0.5*CEPLIFTER*Math.sin(Math.PI*(j+1)/CEPLIFTER);
			}
		}
		private function debugLog(samples:Vector.<Number>, fromIndex:uint, length:uint):void {
			for(var i:uint= fromIndex; i< fromIndex+ length; i++) {
				trace(samples[i]);
			}
		}
	} 	
}