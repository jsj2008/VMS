#include "back_xml_parser.h"
#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/xml_parser.hpp>

back_xml_parser::back_xml_parser(const std::string& xml)
{
	valid = false;
	items = NULL;
	item_count = 0;
	record_type_count = 0;
	record_types = NULL;

	boost::property_tree::ptree xml_tree;
	std::stringstream stream(xml);
	try
	{
		boost::property_tree::xml_parser::read_xml(stream, xml_tree);

		begin_time = xml_tree.get<std::string>("vms_plugin.begin_time");
		end_time = xml_tree.get<std::string>("vms_plugin.end_time");

		boost::property_tree::ptree& types_xml_tree = xml_tree.get_child("vms_plugin.types");
		record_type_count = types_xml_tree.size();
		record_types = new int[record_type_count];
		int index = 0;
		for(boost::property_tree::ptree::iterator it = types_xml_tree.begin(); it != types_xml_tree.end(); ++it)  
		{
			std::string data = it->second.data();
			record_types[index] = atoi(data.c_str());
			index++;
		}

		boost::property_tree::ptree& videos_xml_tree = xml_tree.get_child("vms_plugin.videos");
		item_count = videos_xml_tree.size();
		items = new back_video_item[item_count];
		index = 0;
		for(boost::property_tree::ptree::iterator it = videos_xml_tree.begin(); it != videos_xml_tree.end(); ++it)  
		{
			items[index].video_id = it->second.get<unsigned int>("vid");
			index++;
		}
	}
	catch (const boost::property_tree::ptree_error&)
	{
		if(items)
			delete[] items;
		item_count = 0;
		if(record_types)
			delete[] record_types;
		record_type_count = 0;
		return ;
	}
	valid = true;
}

back_xml_parser::~back_xml_parser()
{
	if(items)
		delete[] items;
}	