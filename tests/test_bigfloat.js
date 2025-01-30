"use strict";

function assert(actual, expected, message) {
    if (arguments.length == 1)
        expected = true;

    if (actual === expected)
        return;

    if (actual !== null && expected !== null
        && typeof actual == 'object' && typeof expected == 'object'
        && actual.toString() === expected.toString())
        return;

    throw Error("assertion failed: got |" + actual + "|" +
        ", expected |" + expected + "|" +
        (message ? " (" + message + ")" : ""));
}

function assertThrows(err, func) {
    var ex;
    ex = false;
    try {
        func();
    } catch (e) {
        ex = true;
        assert(e instanceof err);
    }
    assert(ex, true, "exception expected");
}

// load more elaborate version of assert if available
try {
    __loadScript("test_assert.js");
} catch (e) {
}

/*----------------*/

/* a must be < b */
function test_less(a, b) {
    assert(a < b);
    assert(!(b < a));
    assert(a <= b);
    assert(!(b <= a));
    assert(b > a);
    assert(!(a > b));
    assert(b >= a);
    assert(!(a >= b));
    assert(a != b);
    assert(!(a == b));
}

/* a must be numerically equal to b */
function test_eq(a, b) {
    assert(a == b);
    assert(b == a);
    assert(!(a != b));
    assert(!(b != a));
    assert(a <= b);
    assert(b <= a);
    assert(!(a < b));
    assert(a >= b);
    assert(b >= a);
    assert(!(a > b));
}

function test_divrem(div1, a, b, q) {
    var div, divrem, t;
    div = BigInt[div1];
    divrem = BigInt[div1 + "rem"];
    assert(div(a, b) == q);
    t = divrem(a, b);
    assert(t[0] == q);
    assert(a == b * q + t[1]);
}

function test_idiv1(div, a, b, r) {
    test_divrem(div, a, b, r[0]);
    test_divrem(div, -a, b, r[1]);
    test_divrem(div, a, -b, r[2]);
    test_divrem(div, -a, -b, r[3]);
}

/* QuickJS BigInt extensions */
function test_bigint_ext() {
    var r;
    assert(BigInt.floorLog2(0n) === -1n);
    assert(BigInt.floorLog2(7n) === 2n);

    assert(BigInt.sqrt(0xffffffc000000000000000n) === 17592185913343n);
    r = BigInt.sqrtrem(0xffffffc000000000000000n);
    assert(r[0] === 17592185913343n);
    assert(r[1] === 35167191957503n);

    test_idiv1("tdiv", 3n, 2n, [1n, -1n, -1n, 1n]);
    test_idiv1("fdiv", 3n, 2n, [1n, -2n, -2n, 1n]);
    test_idiv1("cdiv", 3n, 2n, [2n, -1n, -1n, 2n]);
    test_idiv1("ediv", 3n, 2n, [1n, -2n, -1n, 2n]);
}

function test_bigfloat() {
    var e, a, b, sqrt2;

    assert(typeof 1n === "bigint");
    assert(typeof 1
    l === "bigfloat"
)

    assert(1 == 1.0
    l
)

    assert(1 !== 1.0
    l
)


    test_less(2
    l, 3
    l
)

    test_eq(3
    l, 3
    l
)


    test_less(2, 3
    l
)

    test_eq(3, 3
    l
)


    test_less(2.1, 3
    l
)

    test_eq(Math.sqrt(9), 3
    l
)


    test_less(2n, 3
    l
)

    test_eq(3n, 3
    l
)


    e = new BigFloatEnv(128);
    assert(e.prec == 128);
    a = BigFloat.sqrt(2
    l, e
)

    assert(a === BigFloat.parseFloat("0x1.6a09e667f3bcc908b2fb1366ea957d3e", 0, e));
    assert(e.inexact === true);
    assert(BigFloat.fpRound(a) == 0x1
    .6
    a09e667f3bcc908b2fb1366ea95l
)


    b = BigFloatEnv.setPrec(BigFloat.sqrt.bind(null, 2), 128);
    assert(a === b);

    assert(BigFloat.isNaN(BigFloat(NaN)));
    assert(BigFloat.isFinite(1
    l
))

    assert(!BigFloat.isFinite(1
    l / 0
    l
))


    assert(BigFloat.abs(-3
    l
) ===
    3
    l
)

    assert(BigFloat.sign(-3
    l
) ===
    -1
    l
)


    assert(BigFloat.exp(0.2
    l
) ===
    1.2214027581601698339210719946396742
    l
)

    assert(BigFloat.log(3
    l
) ===
    1.0986122886681096913952452369225256
    l
)

    assert(BigFloat.pow(2.1
    l, 1.6
    l
) ===
    3.277561666451861947162828744873745
    l
)


    assert(BigFloat.sin(-1
    l
) ===
    -0.841470984807896506652502321630299
    l
)

    assert(BigFloat.cos(1
    l
) ===
    0.5403023058681397174009366074429766
    l
)

    assert(BigFloat.tan(0.1
    l
) ===
    0.10033467208545054505808004578111154
    l
)


    assert(BigFloat.asin(0.3
    l
) ===
    0.30469265401539750797200296122752915
    l
)

    assert(BigFloat.acos(0.4
    l
) ===
    1.1592794807274085998465837940224159
    l
)

    assert(BigFloat.atan(0.7
    l
) ===
    0.610725964389208616543758876490236
    l
)

    assert(BigFloat.atan2(7.1
    l, -5.1
    l
) ===
    2.1937053809751415549388104628759813
    l
)


    assert(BigFloat.floor(2.5
    l
) ===
    2
    l
)

    assert(BigFloat.ceil(2.5
    l
) ===
    3
    l
)

    assert(BigFloat.trunc(-2.5
    l
) ===
    -2
    l
)

    assert(BigFloat.round(2.5
    l
) ===
    3
    l
)


    assert(BigFloat.fmod(3
    l, 2
    l
) ===
    1
    l
)

    assert(BigFloat.remainder(3
    l, 2
    l
) ===
    -1
    l
)


    /* string conversion */
    assert((1234.125
    l
).
    toString(), "1234.125"
)

    assert((1234.125
    l
).
    toFixed(2), "1234.13"
)

    assert((1234.125
    l
).
    toFixed(2, "down"), "1234.12"
)

    assert((1234.125
    l
).
    toExponential(), "1.234125e+3"
)

    assert((1234.125
    l
).
    toExponential(5), "1.23413e+3"
)

    assert((1234.125
    l
).
    toExponential(5, BigFloatEnv.RNDZ), "1.23412e+3"
)

    assert((1234.125
    l
).
    toPrecision(6), "1234.13"
)

    assert((1234.125
    l
).
    toPrecision(6, BigFloatEnv.RNDZ), "1234.12"
)


    /* string conversion with binary base */
    assert((0x123
    .438
    l
).
    toString(16), "123.438"
)

    assert((0x323
    .438
    l
).
    toString(16), "323.438"
)

    assert((0x723
    .438
    l
).
    toString(16), "723.438"
)

    assert((0xf23
    .438
    l
).
    toString(16), "f23.438"
)

    assert((0x123
    .438
    l
).
    toFixed(2, BigFloatEnv.RNDNA, 16), "123.44"
)

    assert((0x323
    .438
    l
).
    toFixed(2, BigFloatEnv.RNDNA, 16), "323.44"
)

    assert((0x723
    .438
    l
).
    toFixed(2, BigFloatEnv.RNDNA, 16), "723.44"
)

    assert((0xf23
    .438
    l
).
    toFixed(2, BigFloatEnv.RNDNA, 16), "f23.44"
)

    assert((0x0
    .0000438
    l
).
    toFixed(6, BigFloatEnv.RNDNA, 16), "0.000044"
)

    assert((0x1230000000
    l
).
    toFixed(1, BigFloatEnv.RNDNA, 16), "1230000000.0"
)

    assert((0x123
    .438
    l
).
    toPrecision(5, BigFloatEnv.RNDNA, 16), "123.44"
)

    assert((0x123
    .438
    l
).
    toPrecision(5, BigFloatEnv.RNDZ, 16), "123.43"
)

    assert((0x323
    .438
    l
).
    toPrecision(5, BigFloatEnv.RNDNA, 16), "323.44"
)

    assert((0x723
    .438
    l
).
    toPrecision(5, BigFloatEnv.RNDNA, 16), "723.44"
)

    assert((-0xf23
    .438
    l
).
    toPrecision(5, BigFloatEnv.RNDD, 16), "-f23.44"
)

    assert((0x123
    .438
    l
).
    toExponential(4, BigFloatEnv.RNDNA, 16), "1.2344p+8"
)

}

function test_bigdecimal() {
    assert(1
    m === 1
    m
)

    assert(1
    m !== 2
    m
)

    test_less(1
    m, 2
    m
)

    test_eq(2
    m, 2
    m
)


    test_less(1, 2
    m
)

    test_eq(2, 2
    m
)


    test_less(1.1, 2
    m
)

    test_eq(Math.sqrt(4), 2
    m
)


    test_less(2n, 3
    m
)

    test_eq(3n, 3
    m
)


    assert(BigDecimal("1234.1") === 1234.1
    m
)

    assert(BigDecimal("    1234.1") === 1234.1
    m
)

    assert(BigDecimal("    1234.1  ") === 1234.1
    m
)


    assert(BigDecimal(0.1) === 0.1
    m
)

    assert(BigDecimal(123) === 123
    m
)

    assert(BigDecimal(true) === 1
    m
)


    assert(123
    m + 1
    m === 124
    m
)

    assert(123
    m - 1
    m === 122
    m
)


    assert(3.2
    m * 3
    m === 9.6
    m
)

    assert(10
    m / 2
    m === 5
    m
)

    assertThrows(RangeError, () => {
        10
        m / 3
        m
    });

    assert(10
    m % 3
    m === 1
    m
)

    assert(-10
    m % 3
    m === -1
    m
)


    assert(1234.5
    m ** 3
    m === 1881365963.625
    m
)

    assertThrows(RangeError, () => {
        2
        m ** 3.1
        m
    });
    assertThrows(RangeError, () => {
        2
        m ** -3
        m
    });

    assert(BigDecimal.sqrt(2
    m,
        {
            roundingMode: "half-even",
            maximumSignificantDigits: 4
        }
) ===
    1.414
    m
)

    assert(BigDecimal.sqrt(101
    m,
        {
            roundingMode: "half-even",
            maximumFractionDigits: 3
        }
) ===
    10.050
    m
)

    assert(BigDecimal.sqrt(0.002
    m,
        {
            roundingMode: "half-even",
            maximumFractionDigits: 3
        }
) ===
    0.045
    m
)


    assert(BigDecimal.round(3.14159
    m,
        {
            roundingMode: "half-even",
            maximumFractionDigits: 3
        }
) ===
    3.142
    m
)


    assert(BigDecimal.add(3.14159
    m, 0.31212
    m,
        {
            roundingMode: "half-even",
            maximumFractionDigits: 2
        }
) ===
    3.45
    m
)

    assert(BigDecimal.sub(3.14159
    m, 0.31212
    m,
        {
            roundingMode: "down",
            maximumFractionDigits: 2
        }
) ===
    2.82
    m
)

    assert(BigDecimal.mul(3.14159
    m, 0.31212
    m,
        {
            roundingMode: "half-even",
            maximumFractionDigits: 3
        }
) ===
    0.981
    m
)

    assert(BigDecimal.mod(3.14159
    m, 0.31211
    m,
        {
            roundingMode: "half-even",
            maximumFractionDigits: 4
        }
) ===
    0.0205
    m
)

    assert(BigDecimal.div(20
    m, 3
    m,
        {
            roundingMode: "half-even",
            maximumSignificantDigits: 3
        }
) ===
    6.67
    m
)

    assert(BigDecimal.div(20
    m, 3
    m,
        {
            roundingMode: "half-even",
            maximumFractionDigits: 50
        }
) ===
    6.66666666666666666666666666666666666666666666666667
    m
)


    /* string conversion */
    assert((1234.125
    m
).
    toString(), "1234.125"
)

    assert((1234.125
    m
).
    toFixed(2), "1234.13"
)

    assert((1234.125
    m
).
    toFixed(2, "down"), "1234.12"
)

    assert((1234.125
    m
).
    toExponential(), "1.234125e+3"
)

    assert((1234.125
    m
).
    toExponential(5), "1.23413e+3"
)

    assert((1234.125
    m
).
    toExponential(5, "down"), "1.23412e+3"
)

    assert((1234.125
    m
).
    toPrecision(6), "1234.13"
)

    assert((1234.125
    m
).
    toPrecision(6, "down"), "1234.12"
)

    assert((-1234.125
    m
).
    toPrecision(6, "floor"), "-1234.13"
)

}

test_bigint_ext();
test_bigfloat();
test_bigdecimal();
