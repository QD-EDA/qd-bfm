// SPDX-License-Identifier: Apache-2.0
// Directive only, no design element. List it first in a compile whose leading
// sources are third-party (Caliptra) files that declare no time unit: they
// then take QD-BFM's 1ns/1ps from this earlier `timescale (IEEE 1800-2023
// 3.14.2.3 rule b) instead of a tool default, which does not count as
// specified. Needs a single compilation unit (Icarus; Eve --single-unit).
`timescale 1ns/1ps
