#pragma once

#include "config.h"
#include <string>

class back_video_item
{
public:
	unsigned int video_id;
};

class back_xml_parser
{
public:
	back_xml_parser(const std::string& xml);
	~back_xml_parser();

	bool valid;

	back_video_item* items;
	int item_count;

	std::string begin_time;
	std::string end_time;
	int* record_types;
	int record_type_count;
};
