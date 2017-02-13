#pragma once

#include "config.h"
#include <string>

class ptz_xml_parser
{
public:
	ptz_xml_parser(const std::string& xml);
	~ptz_xml_parser();

	bool valid;
	int type;
	int param1;
	int param2;
	int param3;
	int param4;
	std::string param5;
};
