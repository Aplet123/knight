#!/usr/bin/env node
import { run } from '../src/index.js';

//run('E ` + "cat " P');
run('E ` + "cat " "../../knight.kn"');
// run(`
// ; = fizzbuzz BLOCK
// 	; = n 0
// 	; = max +(1 max)
// 	: WHILE ( <( =(n + 1 n) max)
// 		: OUTPUT(
// 			IF (! (% n 15)) "FizzBuzz"
// 			IF (! (% n  5)) "Fizz"
// 			IF (! (% n  3)) "Buzz"
// 			                n)
// ; = max 100
// : CALL fizzbuzz
// `);