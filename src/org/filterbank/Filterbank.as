package org.filterbank {
	public class Filterbank {
		private var _numCept:Number;
		private var _filters:Vector.<Filter>;	

		// TODO should take a config file	      
  		public function Filterbank() {
  			_numCept = 5; // 12
  			// init _filter
  			_filters = new Vector.<Filter> (_numCept);
  			// for now
  			_filters[0] = new Filter(0.0, 200.0, 2.0);
			_filters[1] = new Filter(100.0, 350.0, 2.0);
			_filters[2] = new Filter(200.0, 500.0, 2.0);
			_filters[3] = new Filter(400.0, 800.0, 2.0);
			_filters[4] = new Filter(500.0, 1000.0, 2.0);
  		}

  		public function melspec (samples:Vector.<Number>, spacing:Number) : Vector.<Number> {
  			var vec:Vector.<Number> = new Vector.<Number> (_numCept); 
  			var i:int;
  			for (i=0; i<_numCept; i++) {
  				var filter:Filter = _filters[i];
  				vec[i] = filter.filteredResult(samples, spacing);
  			}
  			return vec;
  		}
	}
}