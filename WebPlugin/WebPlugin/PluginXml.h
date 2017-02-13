#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>

#define PLUGIN_XML_PATH_RESULT "vms_plugin.result"
#define PLUGIN_XML_PATH_VID "vms_plugin.vid"
#define PLUGIN_XML_PATH_FILE_PATH "vms_plugin.path"

inline bool get_parse_xml(const std::string& xml, boost::property_tree::ptree& xml_tree)
{
	std::stringstream stream(xml);
	try
	{
		boost::property_tree::xml_parser::read_xml(stream, xml_tree);
	}
	catch (const boost::property_tree::xml_parser::xml_parser_error&)
	{
		return false;
	}
	return true;
}


inline std::string create_simple_response_xml(int result)
{
	boost::property_tree::ptree xml_tree;
	xml_tree.put(PLUGIN_XML_PATH_RESULT, result);
	std::stringstream stream;
	boost::property_tree::xml_parser::write_xml(stream, xml_tree);
	return stream.str();
}