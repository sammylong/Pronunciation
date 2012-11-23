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
		private static const NUMCEPS:int = 12;
		private static const CEPLIFTER:int = 22;
		
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
			
			// prepare the vectors
			var xRe:Vector.<Number> = new Vector.<Number>(N);
			var xIm:Vector.<Number> = new Vector.<Number>(N);
			
			
			// make a test
			for (var x:int=0; x<16; x++) {
				xRe[x] = x + 1;
				xIm[x] = 0.0;
			}
			var fftTest:FFT2 = new FFT2();
			fftTest.init(4);
			fftTest.run(xRe, xIm);
			trace("test xRe ", xRe);
			trace("test xIm ", xIm);
			
			// container for average value
			var avgCoefs:Vector.<Number> = new Vector.<Number>(NUMCEPS);
			// zero it all
			for each (var num:Number in avgCoefs) {
				num = 0.0;
			}

			var features:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>();
			for (var i:uint=0; i<numFrames; i++) { // only x frames for now
				// result container
				var cc:Vector.<Number> = new Vector.<Number>(NUMCEPS);

				var magnitudes:Number = 0.0;
				// coyp the ones in the window				
				for (var j:int=0; j<N; j++) {
					xRe[j] = samples[SHIFT*i + j];
					xIm[j] = 0.0;
					magnitudes += xRe[j];
				}
				if (magnitudes == 0) continue;
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
				// log
				for (j=0; j<NUMCEPS; j++) {
					m[j] = Math.log(m[j]);
				}
				trace(i + " m " + m);

				// dct
				var numChans:Number = _filterbank.numChans as Number; 
				for (j=0; j<NUMCEPS; j++) {
					var sum:Number = 0.0;
					for (var k:int=0; k<numChans; k++) {
						var factor:Number = Math.cos((Math.PI*j/numChans)*(k-0.5));
						sum+= m[k]*factor;
					}
					cc[j] = Math.sqrt(2.0/numChans)*sum;
				}
				trace(i + " c " + cc);
				// ceptstral lifter
				for (j=0; j<NUMCEPS; j++) {
					cc[j] *= 1 + 0.5*CEPLIFTER*Math.sin(Math.PI*j/CEPLIFTER);
					if (!isNaN(cc[j])) {
						avgCoefs[j] += cc[j]/numFrames;
					}
				}
				features[i] = cc;
			}
			
			// subtract average
			for each (var f:Vector.<Number> in features) {
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
		}
		
// Helpers		
		private function populateHammingWindow(hamming:Vector.<Number>):void {
			for(var i:int=0; i<N; i++) {
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