// Copyright (c) 2002-present, OpenMS Inc. -- EKU Tuebingen, ETH Zurich, and FU Berlin
// SPDX-License-Identifier: BSD-3-Clause
// Extracted from BrukerTimsFile_test.cpp; the reader remains in OpenMS Core.

#include <OpenMS/CONCEPT/ClassTest.h>
#include <OpenMS/ANALYSIS/ID/ProSEAlgorithm.h>
#include <OpenMS/CONCEPT/Constants.h>
#include <OpenMS/FORMAT/BrukerTimsFile.h>
#include <OpenMS/FORMAT/FASTAFile.h>
#include <OpenMS/IONMOBILITY/IMTypes.h>
#include <OpenMS/METADATA/ProteinIdentification.h>

using namespace OpenMS;
using namespace std;

START_TEST(ProSEBrukerTims, "$Id$")

START_SECTION(DDA search engine IM annotation integration test)
{
  // Load real DDA-PASEF data
  BrukerTimsFile f;
  MSExperiment exp;
  f.load(OPENTIMS_DDA_TEST_DATA, exp);

  // Verify MS2 spectra have drift times (pre-condition for IM annotation)
  Size ms2_count = 0;
  Size ms2_with_im = 0;
  for (const auto& spec : exp)
  {
    if (spec.getMSLevel() == 2)
    {
      ++ms2_count;
      if (IMTypes::determineIMFormat(spec) == IMFormat::IM_SPECTRUM)
      {
        ++ms2_with_im;
      }
    }
  }
  TEST_TRUE(ms2_count > 0)
  TEST_EQUAL(ms2_with_im, ms2_count) // all MS2 spectra should have drift time

  // Run ProSEAlgorithm in-memory with the same FASTA and
  // parameters used by the TOPP-level DDA tests for SSE and FI.
  // The key test: any PSMs produced must have IM annotation.
  vector<FASTAFile::FASTAEntry> fasta_db;
  FASTAFile().load(OPENTIMS_TEST_FASTA, fasta_db);
  TEST_TRUE(fasta_db.size() > 0)

  // Typical timsTOF Pro DDA-PASEF search parameters
  ProSEAlgorithm algo;
  Param p = algo.getParameters();
  p.setValue("precursor:mass_tolerance_lower", 20.0);
  p.setValue("precursor:mass_tolerance_upper", 20.0);
  p.setValue("precursor:mass_tolerance_unit", "ppm");
  p.setValue("fragment:mass_tolerance", 20.0);
  p.setValue("fragment:mass_tolerance_unit", "ppm");
  p.setValue("enzyme", "Trypsin/P");
  p.setValue("peptide:missed_cleavages", 2);
  p.setValue("modifications:variable", std::vector<std::string>{"Oxidation (M)", "Acetyl (Protein N-term)"});
  algo.setParameters(p);

  vector<ProteinIdentification> prot_ids;
  PeptideIdentificationList pep_ids;
  auto ec = algo.search(exp, fasta_db, prot_ids, pep_ids);

  TEST_EQUAL(ec == ProSEAlgorithm::ExitCodes::EXECUTION_OK, true)
  TEST_EQUAL(prot_ids.size(), 1)

  // Verify IM annotation: every PSM must have IM meta value (all MS2 spectra have drift time)
  for (const auto& pid : pep_ids)
  {
    TEST_EQUAL(pid.metaValueExists(Constants::UserParam::IM), true)
    if (pid.metaValueExists(Constants::UserParam::IM))
    {
      double im_val = pid.getMetaValue(Constants::UserParam::IM);
      TEST_TRUE(im_val > 0.0) // 1/K0 values are positive
    }
  }

  // If we got any PSMs, verify IM unit on ProteinIdentification
  if (!pep_ids.empty())
  {
    TEST_EQUAL(prot_ids[0].metaValueExists(Constants::UserParam::IM), true)
    if (prot_ids[0].metaValueExists(Constants::UserParam::IM))
    {
      TEST_STRING_EQUAL(prot_ids[0].getMetaValue(Constants::UserParam::IM).toString(), "1/K0")
    }
  }
}
END_SECTION

END_TEST
