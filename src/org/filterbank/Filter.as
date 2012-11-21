package org.filterbank {

	public class Filter {                     // triangular
		private var _start:Number;		      // starting point (frequency domain)
		private var _end:Number;		      // end point
		private var _height:Number = 1.0; 
 
		public function Filter(start:Number, end:Number, height:Number) {
			_start = start;
			_end = end;
			_height = height;
		}   

		public function filteredResult(samples:Vector.<Number>, spacing:Number) : Number {
			var i:int;
			var ret:Number = 0.0;
			var startIndex:int = Math.floor(_start/spacing) as int;
			var endIndex:int = Math.ceil(_end/spacing) as int;
			for (i=startIndex; i<=endIndex; i++) {
				ret += samples[i] * this.heightAtFrequency(spacing * i);
			}
			return ret;
		}

		private function get middle() : Number {
			return (_start + _end)/2.0;
		}

		private function heightAtFrequency(freq:Number) : Number {
			var ret:Number = 0.0;
			var middle:Number = this.middle;
			var m:Number = _height/(middle - _start);
			if (freq >= _start || freq < middle) {
				ret = (freq - _start)*m;
			} else if (freq >= this.middle || freq < _end) {
				ret = (_end - freq)*m;
			}
			return ret;
		}
	}
}