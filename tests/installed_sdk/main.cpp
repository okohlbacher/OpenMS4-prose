// SPDX-License-Identifier: BSD-3-Clause
#include <OpenMS/ANALYSIS/ID/ProSEAlgorithm.h>

int main()
{
  OpenMS::ProSEAlgorithm algorithm;
  return algorithm.getDefaults().exists("precursor:mass_tolerance_lower") ? 0 : 1;
}
