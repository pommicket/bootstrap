#ifndef _MATH_H
#define _MATH_H

#include <stdc_common.h>
#define HUGE_VAL _INFINITY // glibc defines HUGE_VAL as infinity (the C standard only requires it to be positive, funnily enough)
#define _NAN (-(_INFINITY-_INFINITY))
#define _PI 3.141592653589793
#define _2PI 6.283185307179586
#define _HALF_PI 1.5707963267948966
#define _THREE_HALVES_PI 4.71238898038469

// NOTE: these functions are not IEEE 754-compliant (the C standard doesn't require them to be), but they're pretty good

double frexp(double value, int *exp) {
	if (value == 0) {
		*exp = 0;
		return 0;
	}
	unsigned long u = *(unsigned long *)&value, significand;
	*exp = ((u >> 52) & 0x7ff) - 1022;
	// replace exponent with 1022
	u &= 0x800fffffffffffff;
	u |= 0x3fe0000000000000;
	return *(double *)&u;
}

double ldexp(double x, int exp) {
	int e;
	double y = frexp(x, &e);
	// since x = y * 2^e,  x * 2^exp = y * 2^(e+exp)
	exp += e;
	if (exp < -1022) return 0;
	if (exp > 1023) return _INFINITY;
	unsigned long pow2 = (unsigned long)(exp + 1023) << 52;
	return y * *(double *)&pow2;
}

double floor(double x) {
	if (x >= 0.0) {
		if (x > 1073741824.0 * 1073741824.0)
			return x; // floats this big must be integers
		return (unsigned long)x;
	} else {
		if (x < -1073741824.0 * 1073741824.0)
			return x; // floats this big must be integers
		double i = (long)x;
		if (x == i) return x;
		return i - 1.0;
	}
}

double ceil(double x) {
	double f = floor(x);
	if (x == f) return f;
	return f + 1.;
}

double fabs(double x) {
	// this is better than x >= 0 ? x : -x because it deals with -0 properly
	unsigned long u = *(unsigned long *)&x;
	u &= 0x7fffffffffffffff;
	return *(double *)&u;
}

double fmod(double x, double y) {
	if (y == 0.0) {
		errno = EDOM;
		return 0.0;
	}
	return x - (floor(x / y) * y);
}

double _sin_taylor(double x) {
	double i;
	double term = x;
	// taylor expansion for sin:   x - x³/3! + x⁵/5! - ...
	
	// https://en.wikipedia.org/wiki/Kahan_summation_algorithm
	double prev = -1.0;
	double sum = 0.0;
	double c = 0.0;
	for (i = 0.0; i < 100.0 && sum != prev; ++i) {
		prev = sum;
		double y = term - c;
		double t = sum + y;
		c = (t - sum) - y;
		sum = t;
		term *= -(x * x) / ((2.0*i+2.0)*(2.0*i+3.0));
	}
	return sum;
}

double _cos_taylor(double x) {
	double i;
	double term = 1.0;
	// taylor expansion for cos:   1 - x²/2! + x⁴/4! - ...
	
	// https://en.wikipedia.org/wiki/Kahan_summation_algorithm
	double prev = -1.0;
	double sum = 0.0;
	double c = 0.0;
	for (i = 0.0; i < 100.0 && sum != prev; ++i) {
		prev = sum;
		double y = term - c;
		double t = sum + y;
		c = (t - sum) - y;
		sum = t;
		term *= -(x * x) / ((2.0*i+1.0)*(2.0*i+2.0));
	}
	return sum;
}

double sin(double x) {
	x = fmod(x, 2.0*_PI);
	// the Taylor series works best for small inputs. so, provide _sin_taylor with a value in the range [0,π/2]
	if (x < _HALF_PI)
		return _sin_taylor(x);
	if (x < _PI)
		return _sin_taylor(_PI - x);
	if (x < _THREE_HALVES_PI)
		return -_sin_taylor(x - _PI);
	return -_sin_taylor(_2PI - x);
}

double cos(double x) {
	x = fmod(x, 2.0*_PI);
	// the Taylor series works best for small inputs. so, provide _cos_taylor with a value in the range [0,π/2]
	if (x < _HALF_PI)
		return _cos_taylor(x);
	if (x < _PI)
		return -_cos_taylor(_PI - x);
	if (x < _THREE_HALVES_PI)
		return -_cos_taylor(x - _PI);
	return _cos_taylor(_2PI - x);
}

double tan(double x) {
	return sin(x)/cos(x);
}

// for sqrt and the inverse trigonometric functions, we use Newton's method
// https://en.wikipedia.org/wiki/Newton%27s_method

double sqrt(double x) {
	if (x < 0.0) {
		errno = EDOM;
		return _NAN;
	}
	if (x == 0.0) return 0.0;
	if (x == _INFINITY) return _INFINITY;
	// we want to find the root of: f(t) = t² - x
	//                              f'(t) = 2t
	int exp;
	double y = frexp(x, &exp);
	if (exp & 1) {
		y *= 2;
		--exp;
	}
	// newton's method will be slow for very small or very large numbers.
	// so we have ensured that
	//     0.5 ≤ y < 2
	// and also x = y * 2^exp; sqrt(x) = sqrt(y) * 2^(exp/2)  NB: we've ensured that exp is even
	
	// 7 iterations seems to be more than enough for any number
	double t = y;
	t = (y / t + t) * 0.5;
	t = (y / t + t) * 0.5;
	t = (y / t + t) * 0.5;
	t = (y / t + t) * 0.5;
	t = (y / t + t) * 0.5;
	t = (y / t + t) * 0.5;
	t = (y / t + t) * 0.5;
	
	return ldexp(t, exp>>1);
	
}

double _acos_newton(double x) {
	// we want to find the root of: f(t) = cos(t) - x
	//                              f'(t) = -sin(t)
	double t = _HALF_PI - x; // reasonably good first approximation
	double prev_t = -100.0;
	int i;
	
	for (i = 0; i < 100 && prev_t != t; ++i) {
		prev_t = t;
		t += (cos(t) - x) / sin(t);
	}
	return t;
}

double _asin_newton(double x) {
	// we want to find the root of: f(t) = sin(t) - x
	//                              f'(t) = cos(t)
	double t = x; // reasonably good first approximation
	double prev_t = -100.0;
	int i;
	
	for (i = 0; i < 100 && prev_t != t; ++i) {
		prev_t = t;
		t += (x - sin(t)) / cos(t);
	}
	return t;
}

double acos(double x) {
	if (x > 1.0 || x < -1.0) {
		errno = EDOM;
		return _NAN;
	}
	// Newton's method doesn't work well near -1 and 1, because f(x) / f'(x) is very large.
	if (x > 0.8)
		return _asin_newton(sqrt(1-x*x));
	if (x < -0.8)
		return _PI-_asin_newton(sqrt(1-x*x));
	
	return _acos_newton(x);
}

double asin(double x) {
	if (x > 1.0 || x < -1.0) {
		errno = EDOM;
		return _NAN;
	}
	// Newton's method doesn't work well near -1 and 1, because f(x) / f'(x) is very large.
	if (x > 0.8)
		return _acos_newton(sqrt(1.0-x*x));
	if (x < -0.8)
		return -_acos_newton(sqrt(1.0-x*x));
	
	return _asin_newton(x);
}

double atan(double x) {
	// the formula below breaks for really large inputs; tan(10^20) as a double is indistinguishable from pi/2 anyways
	if (x > 1e20) return _HALF_PI;
	if (x < -1e20) return -_HALF_PI;
	
	// we can use a nice trigonometric identity here
	return asin(x / sqrt(1+x*x));
}

double atan2(double y, double x) {
	if (x == 0.0) {
		if (y > 0.0) return _HALF_PI;
		if (y < 0.0) return -_HALF_PI;
		return 0.0; // this is what IEEE 754 does
	}
	
	double a = atan(y/x);
	if (x > 0.0) {
		return a;
	} else if (y > 0.0) {
		return a + _PI;
	} else {
		return a - _PI;
	}
}

double _exp_taylor(double x) {
	double i;
	double term = 1.0;
	// taylor expansion for exp:   1 + x/1! + x²/2! + ...
	
	// https://en.wikipedia.org/wiki/Kahan_summation_algorithm
	double prev = -1.0;
	double sum = 0.0;
	double c = 0.0;
	for (i = 1.0; i < 100.0 && sum != prev; ++i) {
		prev = sum;
		double y = term - c;
		double t = sum + y;
		c = (t - sum) - y;
		sum = t;
		term *= x / i;
	}
	return sum;
}

double exp(double x) {
	if (x > 709.782712893384) {
		errno = ERANGE;
		return _INFINITY;
	}
	if (x == 0.0) return 1;
	if (x < -744.4400719213812)
		return 0;
	int i, e;
	double y = frexp(x, &e);
	if (e < 1.0) return _exp_taylor(x);
	// the taylor series doesn't work well for large x (positive or negative),
	// so we use the fact that   exp(y*2^e) = exp(y)^(2^e)
	double value = _exp_taylor(y);
	for (i = 0; i < e; ++i)
		value *= value;
	return value;
}

#define _LOG2 0.6931471805599453

double log(double x) {
	if (x < 0.0) {
		errno = EDOM;
		return _NAN;
	}
	if (x == 0.0) return -_INFINITY;
	if (x == 1.0) return 0.0;
	int e;
	double sum;
	double a = frexp(x, &e);
	// since x = a * 2^e, log(x) = log(a) + log(2^e) = log(a) + e log(2)
	sum = e * _LOG2;
	// now that a is in [1/2,1), the series log(a) = (a-1) - (a-1)²/2 + (a-1)³/3 - ... converges quickly
	
	a -= 1;
	// https://en.wikipedia.org/wiki/Kahan_summation_algorithm
	double prev = HUGE_VAL;
	double c = 0;
	double term = a;
	double i;
	for (i = 1.0; i < 100.0 && sum != prev; ++i) {
		prev = sum;
		double y = term / i - c;
		double t = sum + y;
		c = (t - sum) - y;
		sum = t;
		term *= -a;
	}
	return sum;
}

#define _INVLOG10 0.43429448190325176 // = 1/log(10)
double log10(double x) {
	return log(x) * _INVLOG10;
}

double modf(double value, double *iptr) {
	double m = fmod(value, 1.0);
	if (value >= 0.0) {
		*iptr = value - m;
		return m;
	} else if (m == 0.0) {
		*iptr = value;
		return 0.0;
	} else {
		*iptr = value - m + 1.0;
		return m - 1.0;
	}
}

// double raised to the power of an integer
double _dpowi(double x, unsigned long y) {
	double result = 1.0;
	if (y & 1) {
		--y;
		result *= x;
	}
	if (y > 0) {
		double p = _dpowi(x, y >> 1);
		result *= p * p;
	}
	return result;
}

double pow(double x, double y) {
	if (x > 0.0) {
		return exp(y * log(x));
	} else if (x < 0.0) {
		if (fmod(y, 1.0) != 0) {
			errno = EDOM;
			return _NAN;
		}
		if (y > 1.6602069666338597e+19)
			return x < -1. ? -_INFINITY : 0.;
		if (y < -1.6602069666338597e+19)
			return x < -1. ? 0. : -_INFINITY;
		return _dpowi(x, (unsigned long)y);
	} else {
		if (y < 0) {
			errno = EDOM;
			return _NAN;
		}
		if (y > 0) {
			// 0^x = 0 for x>0
			return 0.;
		}
		// 0^0 = 1
		return 1.;
	}
}

double cosh(double x) {
	double e = exp(x);
	return (e + 1./e) * 0.5;
}

double sinh(double x) {
	double e = exp(x);
	return (e - 1./e) * 0.5;
}

double tanh(double x) {
	if (x > 20.0) return 1.;
	if (x < -20.0) return -1.;
	double e = exp(x);
	double f = 1./e;
	return (e - f) / (e + f);
}
#endif // _MATH_H
