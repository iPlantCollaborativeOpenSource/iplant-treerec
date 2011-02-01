package org.iplantc.tr.demo.client;

import com.google.gwt.core.client.JsArray;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
import com.google.gwt.json.client.JSONValue;

public class TRUtil
{
	static JsArray<JsTRSearchResult> parseFamilies(String json)
	{
		if(json == null) {
			return null;
		}
		
		JSONObject jsonObj = (JSONObject)JSONParser.parseStrict(json);
		JSONValue valItems = null;

		// drill down to families array
		JSONValue val = jsonObj.get("data");

		if(val != null)
		{
			val = ((JSONObject)val).get("item");

			if(val != null)
			{
				valItems = ((JSONObject)val).get("families");
			}
		}

		if(!isEmpty(valItems))
		{
			return JsonUtil.asArrayOf(valItems.toString());
		}
		else {
			return null;
		}
	}
	
	private static boolean isEmpty(JSONValue in)
	{
		boolean ret = true; // assume we have an empty value

		if(in != null)
		{
			String test = in.toString();

			if(test.length() > 0 && !test.equals("[]"))
			{
				ret = false;
			}
		}

		return ret;
	}

}
