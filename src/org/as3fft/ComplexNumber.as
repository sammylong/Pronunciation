package org.as3fft {
	public class ComplexNumber {
		private var _re:Number = 0.0;			// Real component
		private var _im:Number = 0.0;			// Imaginary component
		
		public function ComplexNumber(real:Number, imag:Number) {
			_re = real;
			_im = imag;
		}
		public function get magnitude() : Number {
			return Math.sqrt(Math.pow(_re, 2.0) + Math.pow(_im, 2.0)) ;
		}
	}
}