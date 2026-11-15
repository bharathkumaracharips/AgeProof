pragma circom 2.1.6;

// Compares if in[0] <= in[1] for 32-bit integers
template LessEqThan(n) {
    assert(n <= 252);
    signal input in[2];
    signal output out;

    component comp = LessThan(n);
    comp.in[0] <== in[0];
    comp.in[1] <== in[1] + 1;
    out <== comp.out;
}

// Compares if in[0] < in[1] for n-bit integers
template LessThan(n) {
    assert(n <= 252);
    signal input in[2];
    signal output out;

    component n2b = Num2Bits(n + 1);
    n2b.in <== in[0] + (1 << n) - in[1];
    out <== 1 - n2b.out[n];
}

// Converts a field element to n binary bits
template Num2Bits(n) {
    signal input in;
    signal output out[n];

    var accum = 0;
    for (var i = 0; i < n; i++) {
        out[i] <-- (in >> i) & 1;
        out[i] * (1 - out[i]) === 0;
        accum += out[i] * (1 << i);
    }
    accum === in;
}

// Validates that YYYYMMDD is partitioned into valid calendar ranges
template ValidateDate() {
    signal input date; // YYYYMMDD
    signal output valid;

    // Extract Year, Month, Day
    // year = date \ 10000
    // month = (date % 10000) \ 100
    // day = date % 100
    signal year <-- date \ 10000;
    signal remainder <-- date % 10000;
    signal month <-- remainder \ 100;
    signal day <-- remainder % 100;

    date === year * 10000 + month * 100 + day;

    // Check 1 <= month <= 12
    component monthLower = LessEqThan(8);
    monthLower.in[0] <== 1;
    monthLower.in[1] <== month;
    monthLower.out === 1;

    component monthUpper = LessEqThan(8);
    monthUpper.in[0] <== month;
    monthUpper.in[1] <== 12;
    monthUpper.out === 1;

    // Check 1 <= day <= 31
    component dayLower = LessEqThan(8);
    dayLower.in[0] <== 1;
    dayLower.in[1] <== day;
    dayLower.out === 1;

    component dayUpper = LessEqThan(8);
    dayUpper.in[0] <== day;
    dayUpper.in[1] <== 31;
    dayUpper.out === 1;

    valid <== 1;
}
