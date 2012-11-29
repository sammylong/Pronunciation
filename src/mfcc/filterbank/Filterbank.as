package mfcc.filterbank {
	import flash.utils.ByteArray;
	
	public class Filterbank {
		private var _filters:Vector.<Filter>;	
		private var _numChans:int;
		private var _freqStep:Number;
		private var _centerFreqs:Vector.<Number>;
		private var _lowChans:Vector.<int>;
		private var _lowChanWeights:Vector.<Number>;
		private var _N:uint;
		
  		public function Filterbank(numChans:uint, sampleRate:uint, N:uint) {
			_numChans = numChans;
			_N = N;
			var Nby2:uint = N / 2;
			var maxChan:uint = numChans + 1;
			_freqStep = sampleRate/N;//freq step
			var mlo:Number = 0; 
			var mhi:Number = mel(Nby2,_freqStep);
			// compute center freq for each tri
			_centerFreqs = new Vector.<Number>(numChans + 2);
			for (var chan:uint=0; chan <= maxChan; chan++) {
				_centerFreqs[chan] = ((chan as Number)/maxChan)*(mhi - mlo) + mlo;
				//trace("cf " + chan + " : " +   _centerFreqs[chan]);
			}
			// assign channel to each signal
			_lowChans = new Vector.<int>(Nby2);
			chan = 1;
			var klo:uint = 1;
			for (var k:uint=0; k<Nby2; k++) {
				var melk:Number = mel(k,_freqStep);
				if (k < klo) {
					_lowChans[k] = -1;
				} else {
					while(_centerFreqs[chan] < melk && chan <= maxChan) ++chan;
					_lowChans[k] = chan - 1;
				}
				//trace("loChan " + k + " : " + _lowChans[k]);

			}
			// lower channel weight
			_lowChanWeights = new Vector.<Number>(Nby2);
			for (k=0; k<Nby2; k++) {
				chan = _lowChans[k];
				if (k < klo) {
					_lowChanWeights[k] = 0.0;
				} else {
					_lowChanWeights[k] = (_centerFreqs[chan+1] - mel(k, _freqStep))/(_centerFreqs[chan+1] - _centerFreqs[chan]);
				}
				//trace("loWt " + k + " : " + _lowChanWeights[k]);
			}

  		}
		public function get numChans() : int {
			return _numChans;
		}
  		public function melspec (samples:Vector.<Number>) : Vector.<Number> {
  			var m:Vector.<Number> = new Vector.<Number>(_numChans);
			var Nby2:uint = _N / 2;
			for (var k:uint=1; k<Nby2; k++) {
				var chan:int = _lowChans[k];
				var t:Number = _lowChanWeights[k]*samples[k];
				if (chan>0) {
					m[chan-1]+= _lowChanWeights[k]*samples[k];
				}
				if (chan>0 && chan< _numChans) {
					m[chan]+= (1-_lowChanWeights[k])*samples[k];
				}
			}
			// take logs
			for (chan=0; chan<_numChans; chan++) {
				//m[chan] = Math.max(m[chan], 1.0);
				m[chan] = Math.log(m[chan]);
			}
			return m;
  		}
		private function mel(k:uint, step:Number):Number {
			return 1127.0* Math.log(1 + k*step/700.0);
		}
	}
}