#include "ptz_xml_parser.h"
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>

ptz_xml_parser::ptz_xml_parser(const std::string& xml)
{
	valid = false;

	boost::property_tree::ptree xml_tree;
	std::stringstream stream(xml);
	try
	{
		boost::property_tree::xml_parser::read_xml(stream, xml_tree);
		type = xml_tree.get<unsigned int>("vms_plugin.type");
		param1 = xml_tree.get<int>("vms_plugin.param1");
		param2 = xml_tree.get<int>("vms_plugin.param2");
		param3 = xml_tree.get<int>("vms_plugin.param3");
		param4 = xml_tree.get<int>("vms_plugin.param4");
		param5 = xml_tree.get<std::string>("vms_plugin.param5");

	}
	catch (const boost::property_tree::ptree_error&)
	{
		return ;
	}
	valid = true;
}

ptz_xml_parser::~ptz_xml_parser()
{
	
}	