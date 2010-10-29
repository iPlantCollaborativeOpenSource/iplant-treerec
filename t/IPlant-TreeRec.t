#!/usr/bin/perl;

use warnings;
use strict;

#########################

use Test::More tests => 52;
BEGIN { use_ok('IPlant::DB::TreeRec') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Cv') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Cvterm') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::CvtermDbxref') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::CvtermRelationship') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Cvtermpath') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Cvtermprop') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Cvtermsynonym') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Db') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Dbxref') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Dbxrefprop') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Family') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::FamilyMember') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::GeneIdSearch') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::GoAccessionSearch') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::GoSearch') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::GoTermsForFamily') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Member') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::MemberAttribute') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::ProteinTree') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::ProteinTreeAttribute') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::ProteinTreeMember') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::ProteinTreeNode') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::ProteinTreeNodeAttribute') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Reconciliation') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::ReconciliationNode') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::Sequence') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::SpeciesTree') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::SpeciesTreeAttribute') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::SpeciesTreeNode') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::SpeciesTreeNodeAttribute') };
BEGIN { use_ok('IPlant::DB::TreeRec::Result::SpeciesTreeNodePath') };
BEGIN { use_ok('IPlant::TreeRec') };
BEGIN { use_ok('IPlant::TreeRec::BlastArgs') };
BEGIN { use_ok('IPlant::TreeRec::BlastSearcher') };
BEGIN { use_ok('IPlant::TreeRec::DatabaseTreeLoader') };
BEGIN { use_ok('IPlant::TreeRec::FileRetriever') };
BEGIN { use_ok('IPlant::TreeRec::FileTreeLoader') };
BEGIN { use_ok('IPlant::TreeRec::GeneFamilyInfo') };
BEGIN { use_ok('IPlant::TreeRec::REST') };
BEGIN { use_ok('IPlant::TreeRec::REST::API') };
BEGIN { use_ok('IPlant::TreeRec::REST::API::download') };
BEGIN { use_ok('IPlant::TreeRec::REST::API::download::type') };
BEGIN { use_ok('IPlant::TreeRec::REST::API::download::type::qualifier') };
BEGIN { use_ok('IPlant::TreeRec::REST::API::get') };
BEGIN { use_ok('IPlant::TreeRec::REST::API::get::type') };
BEGIN { use_ok('IPlant::TreeRec::REST::API::get::type::qualifier') };
BEGIN { use_ok('IPlant::TreeRec::REST::API::search') };
BEGIN { use_ok('IPlant::TreeRec::REST::API::search::type') };
BEGIN { use_ok('IPlant::TreeRec::REST::API::search::type::parameters') };
BEGIN { use_ok('IPlant::TreeRec::REST::Handler') };
BEGIN { use_ok('IPlant::TreeRec::REST::Initializer') };

#########################
