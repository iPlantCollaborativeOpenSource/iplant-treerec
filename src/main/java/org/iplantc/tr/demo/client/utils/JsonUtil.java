package org.iplantc.tr.demo.client.utils;

import java.util.List;

import com.google.gwt.core.client.JavaScriptObject;
import com.google.gwt.core.client.JsArray;
import com.google.gwt.json.client.JSONArray;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
import com.google.gwt.json.client.JSONString;
import com.google.gwt.json.client.JSONValue;

/**
 * Provides JSON utility operations.
 */
public class JsonUtil
{
	/**
	 * Returns a JavaScript array representation of JSON argument data.
	 * 
	 * @param <T> type of the elements contains in the JavaScript Array.
	 * @param json a string representing data in JSON format.
	 * @return a JsArray of type T.
	 */
	public static final native <T extends JavaScriptObject> JsArray<T> asArrayOf(String json)
	/*-{
		return eval(json);
	}-*/;

	/**
	 * Remove quotes surrounding a JSON string value.
	 * 
	 * @param value string with quotes.
	 * @return a string without quotes.
	 */
	public static String trim(String value)
	{
		StringBuilder temp = null;
		if(value != null && !value.equals(""))
		{
			final String QUOTE = "\"";

			temp = new StringBuilder(value);

			if(value.startsWith(QUOTE))
			{
				temp.deleteCharAt(0);
			}

			if(value.endsWith(QUOTE))
			{
				temp.deleteCharAt(temp.length() - 1);
			}

			return temp.toString();
		}
		else
		{
			return value;
		}
	}

	/**
	 * Escape new line char in JSON string
	 * 
	 * @param value string to escape.
	 * @return escaped string.
	 */
	public static String escapeNewLine(String value)
	{
		if(value == null || value.equals(""))
		{
			return value;
		}
		else
		{
			return value.replace("\n", "\\n");
		}
	}

	/**
	 * Format strings with new line, tab spaces and carriage returns
	 * 
	 * @param value string to format.
	 * @return formatted string.
	 */
	public static String formatString(String value)
	{
		if(value == null || value.equals(""))
		{
			return value;
		}
		else
		{
			value = value.replace("\\t", "\t");
			value = value.replace("\\r\\n", "\n");
			value = value.replace("\\r", "\n");
			value = value.replace("\\n", "\n");
			return value;
		}
	}

	/**
	 * Check if the json value is empty
	 * 
	 * @param in json value to test
	 * @return true if value is empty else returns false
	 */
	public static boolean isEmpty(JSONValue in)
	{
		boolean ret = true; // assume we have an empty value

		if(in != null)
		{
			String test = in.toString();

			if(test.length() > 0 && !test.equals("[]") && !test.equals("{}"))
			{
				ret = false;
			}
		}

		return ret;
	}

	/**
	 * Creates a JSON object from a string. If the string parses, but doesn't contain a JSON object, null
	 * is returned.
	 * 
	 * @param json
	 * @return
	 */
	public static JSONObject getObject(final String json)
	{
		JSONValue val = JSONParser.parseStrict(json);

		if(val == null)
		{
			return null;
		}
		else
		{
			return val.isObject();
		}
	}

	/**
	 * Parse a string from a JSON object
	 * 
	 * @param jsonObj object to parse.
	 * @param key key for string to retrieve.
	 * @return desired string. Empty string on failure.
	 */
	public static String getString(final JSONObject jsonObj, final String key)
	{
		String ret = ""; // assume failure

		if(jsonObj != null && key != null)
		{
			JSONValue val = jsonObj.get(key);

			if(val != null && val.isNull() == null)
			{
				JSONString strVal = val.isString();

				if(strVal != null)
				{
					ret = strVal.stringValue();
				}
			}
		}

		return ret;
	}
	
	public static String getArrayString(final JSONObject jsonObj, final String key)
	{
		String ret = ""; // assume failure

		if(jsonObj != null && key != null)
		{
			JSONValue val = jsonObj.get(key);

			if(val != null && val.isNull() == null)
			{
					ret = val.toString();
			}
		}

		return ret;
	}

	/**
	 * 
	 * @param jsonObj
	 * @param key
	 * @return
	 */
	public static JSONObject getObject(final JSONObject jsonObj, final String key)
	{
		JSONObject ret = null; // assume failure

		if(jsonObj != null && key != null)
		{
			JSONValue val = jsonObj.get(key);

			if(val != null)
			{
				ret = val.isObject();
			}
		}

		return ret;
	}

	/**
	 * 
	 * @param jsonObj
	 * @param key
	 * @return
	 */
	public static JSONArray getArray(final JSONObject jsonObj, final String key)
	{
		JSONArray ret = null; // assume failure

		if(jsonObj != null && key != null)
		{
			JSONValue val = jsonObj.get(key);

			if(val != null)
			{
				ret = val.isArray();
			}
		}

		return ret;
	}

	/**
	 * Returns the JSONObject at a given array index, or null if there is no JSONObject at that index.
	 * 
	 * @param array
	 * @param index
	 * @return
	 */
	public static JSONObject getObjectAt(JSONArray array, int index)
	{
		JSONValue element = array.get(index);

		if(element == null)
		{
			return null;
		}
		else
		{
			return element.isObject();
		}
	}

	/**
	 * Build a JSON string array from a key and array list.
	 * 
	 * @param key key associated with the array
	 * @param items items to add to the array
	 * @return Correct JSON array.
	 */
	public static String buildStringArray(final String key, List<String> items)
	{
		StringBuffer ret = new StringBuffer();
		ret.append("\"" + key + "\": [");

		if(items != null)
		{
			boolean first = true;
			for(String item : items)
			{
				// make sure we have commas in the right place
				if(first)
				{
					first = false;
				}
				else
				{
					ret.append(", ");
				}

				ret.append("\"" + item + "\"");
			}
		}

		ret.append("]");

		return ret.toString();
	}

	/**
	 * Simple function to wrap quotes around a valid string.
	 * 
	 * @param in string to be quoted.
	 * @return quoted string (if input is not null).
	 */
	public static String quoteString(String in)
	{
		String ret = null; // assume failure

		if(in != null)
		{
			final String QUOTE = "\"";

			ret = QUOTE + in + QUOTE;
		}

		return ret;
	}
}
