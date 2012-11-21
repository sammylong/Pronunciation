package mfcc.filterbank {
	public class Filterbank {
		private static const kNumCept:int = 12;
		private var _filters:Vector.<Filter>;	
		
		// TODO should take a config file	      
  		public function Filterbank() {
  			// init _filter
  			_filters = new Vector.<Filter> (kNumCept);
  			// for now
  			_filters[0] = new Filter(0.0, 200.0, 2.0);
			_filters[1] = new Filter(100.0, 400.0, 2.0);
			_filters[2] = new Filter(200.0, 500.0, 2.0);
			_filters[3] = new Filter(400.0, 800.0, 2.0);
			_filters[4] = new Filter(500.0, 1000.0, 2.0);
			_filters[5] = new Filter(800.0, 1200.0, 2.0);
			_filters[6] = new Filter(1000.0, 1500.0, 2.0);
			_filters[7] = new Filter(1200.0, 1900.0, 2.0);
			_filters[8] = new Filter(1500.0, 2400.0, 2.0);
			_filters[9] = new Filter(1900.0, 2800.0, 2.0);
			_filters[10] = new Filter(2400.0, 3400.0, 2.0);
			_filters[11] = new Filter(2800.0, 4000.0, 2.0);

  		}

  		public function melspec (samples:Vector.<Number>, spacing:Number) : Vector.<Number> {
  			var vec:Vector.<Number> = new Vector.<Number> (kNumCept); 
  			var i:int;
  			for (i=0; i<kNumCept; i++) {
  				var filter:Filter = _filters[i];
  				vec[i] = filter.filteredResult(samples, spacing);
  			}
  			return vec;
  		}
	}
}