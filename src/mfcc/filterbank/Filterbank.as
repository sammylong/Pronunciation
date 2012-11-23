package mfcc.filterbank {
	import flash.utils.ByteArray;
	
	public class Filterbank {
		private var _filters:Vector.<Filter>;	
		
  		public function Filterbank(cStrs:Array) {
			trace("input c: " + cStrs);
			// get cutoff values from the input
			var cutoffs:Array = new Array();
			for each (var str:String in cStrs) {
				var index:int = str.indexOf("e+");
				if (index == -1) continue;
				var number:Number = Number(str.substring(0, index));
				var orderOfMag:Number = Number(str.substring(index + 2, str.length));
				cutoffs.push(number * Math.pow(10, orderOfMag));
			}
			trace("processed c: " + cutoffs);
			var numCeps:uint = cutoffs.length - 2;
  			// init _filter
  			_filters = new Vector.<Filter> (numCeps);
			for (var i:uint=0; i<numCeps; i++) {
				var start:Number = cutoffs[i];
				var end:Number = cutoffs[i+2];
				_filters[i] = new Filter (start, end, 1.0);
			}
			trace("filters length: ", _filters.length);
  		}

  		public function melspec (samples:Vector.<Number>, spacing:Number) : Vector.<Number> {
  			var vec:Vector.<Number> = new Vector.<Number> (_filters.length); 
  			var i:int;
  			for (i=0; i<_filters.length; i++) {
  				var filter:Filter = _filters[i];
  				vec[i] = filter.filteredResult(samples, spacing);
  			}
  			return vec;
  		}
	}
}