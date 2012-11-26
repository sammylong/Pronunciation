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
		private static const NUMCHANS:uint = 26;
		private static const NUMCEPS:int = 12;
		private static const CEPLIFTER:int = 22;
		
		private var _hamming: Vector.<Number>;
		private var _filterbank:Filterbank;

		public function MFCC39() {
			// pre-render the hamming window
			_hamming =   new Vector.<Number>(N); 
			populateHammingWindow(_hamming);
			_filterbank = new Filterbank(NUMCHANS, SAMPLERATE, N);
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

			var numFrames:int = Math.floor(((samples.length as Number) - N)/SHIFT) as int;
			trace("init num frames: ", numFrames);
/*
			// find start frame
			var magnitudes:Number = 0.0;
			var frame:int = 0
			for (frame=0; frame< numFrames; frame++) {
				magnitudes = 0.0;
				for (var i:uint=frame*SHIFT; i<frame*SHIFT+N; i++) {
					magnitudes += Math.abs(samples[i]);
				}
				if (magnitudes >0) break;
			}
			var startFrame:uint = frame;
			// find end frame
			for (frame=numFrames - 1; frame>=0; frame --) {
				magnitudes = 0.0;
				for (i=frame*SHIFT; i<frame*SHIFT+N; i++) {
					magnitudes += Math.abs(samples[i]);
				}
				if (magnitudes >0) break;
			}
			var endFrame:uint = frame;
			numFrames = endFrame - startFrame + 1;
			trace("clipped num frames: ", numFrames);
*/
			var startFrame:uint = 0;
			var endFrame:uint = numFrames - 1;
			// prepare the vectors
			var xRe:Vector.<Number> = new Vector.<Number>(N);
			var xIm:Vector.<Number> = new Vector.<Number>(N);
			
			var features:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			for (var i:uint=startFrame; i<=endFrame ; i++) { // only x frames for now
				// coyp the ones in the window				
				for (var j:int=0; j<N; j++) {
					xRe[j] = samples[SHIFT*i + j];
					xIm[j] = 0.0;
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
				var m:Vector.<Number> = _filterbank.melspec(xMag);
				// log
				for (j=0; j<m.length; j++) {
					m[j] = Math.max(m[j], 1.0);// otherwise the value goes crazy
					m[j] = Math.log(m[j]);
				}
				//trace(i + " mm " + m);

				// cepstral coefs container
				var cc:Vector.<Number> = new Vector.<Number>(NUMCEPS);
				computeCepstralCoef(m, cc);
				//trace(i + " cc " + cc);

				// ceptstral lifter
				cepstralLifter(cc);
				//trace(i + " cc " + cc);
				
				features.push(cc);
			}
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
			// print
			for (j=0; j<20;j++) {
				trace(j + ": " + features[j]);
			}
		}
		private function preEmphasis(samples:Vector.<Number>):void {
			for (var i:int=samples.length - 1; i>0; i--) {
				samples[i] = samples[i] - PREEMCOEF*samples[i-1];
			}
			samples[0] *= (1.0 - PREEMCOEF);
		}
		private function populateHammingWindow(hamming:Vector.<Number>):void {
			for(var i:int=0; i<N; i++) {
				// same as iOS library
				hamming[i] = 0.54 - 0.46 * Math.cos(2.0*Math.PI*i/(N-1.0));
			}
		}
		private function computeCepstralCoef(m:Vector.<Number>, cc:Vector.<Number>):void {
			var numChans:Number = m.length as Number; 
			for (var j:uint=0; j<NUMCEPS; j++) {
				cc[j] = 0.0;
				for (var k:int=0; k<numChans; k++) {
					var factor:Number = Math.cos((Math.PI*(j+1)/numChans)*((k+1)-0.5));
					cc[j]+= Math.sqrt(2.0/numChans)*m[k]*factor;
				}
			}
		}
		private function cepstralLifter(cc:Vector.<Number>):void {
			for (var j:uint=0; j<NUMCEPS; j++) {
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