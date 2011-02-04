package org.iplantc.tr.demo.client.windows;

import org.iplantc.tr.demo.client.utils.JsonUtil;

import com.google.gwt.json.client.JSONObject;

/**
 * Tree reconciliation URL information.
 * 
 * @author Dennis Roberts
 */
public class TRUrlInfo
{
	/**
	 * The key used to refer to the relative URL.
	 */
	private static final String RELATIVE_URL_KEY = "relativeUrl";

	/**
	 * The key used to refer to the file format.
	 */
	private static final String FILE_FORMAT_KEY = "fileFormat";

	/**
	 * The key used to refer to the list of relative URLs.
	 */
	private static final String RELATIVE_URL_LIST_KEY = "relativeUrls";

	/**
	 * The URL used to retrieve the resource.
	 */
	private String url;

	/**
	 * The format of the resource.
	 */
	private String fileFormat;

	/**
	 * Gets the URL used to retrieve the resource.
	 * 
	 * @return the URL.
	 */
	public String getUrl()
	{
		return url;
	}

	/**
	 * Gets the format of the resource.
	 * 
	 * @return the format description.
	 */
	public String getFileFormat()
	{
		return fileFormat;
	}

	/**
	 * Initializes a new URL information object from the given JSON object.
	 * 
	 * @param json the JSON object.
	 */
	public TRUrlInfo(JSONObject json)
	{
		setUrl(json);
		setFileFormat(json);
	}

	/**
	 * Extracts the URL information for the given key from the given gene family details result.
	 * 
	 * @param json the JSON object representing the gene family details.
	 * @param key the key representing the URL information we want to retrieve.
	 * @return the URL information or null if the key isn't found.
	 */
	public static TRUrlInfo extractUrlInfo(JSONObject json, String key)
	{
		TRUrlInfo ret = null;

		if(json.containsKey(RELATIVE_URL_LIST_KEY))
		{
			JSONObject relativeUrlList = JsonUtil.getObject(json, RELATIVE_URL_LIST_KEY);

			if(relativeUrlList.containsKey(key))
			{
				ret = new TRUrlInfo(JsonUtil.getObject(relativeUrlList, key));
			}
		}

		return ret;
	}

	/**
	 * Sets the file format using information from the given JSON object.
	 * 
	 * @param json the JSON object.
	 */
	private void setFileFormat(JSONObject json)
	{
		if(json.containsKey(RELATIVE_URL_KEY))
		{
			String relativeUrl = json.get(RELATIVE_URL_KEY).isString().stringValue();
			String baseUrl = "http://gargery.iplantcollaborative.org/";
			url = baseUrl + "treereconciliation/" + relativeUrl;
		}
	}

	/**
	 * Sets the URL using information from the given JSON object.
	 * 
	 * @param json the JSON object.
	 */
	private void setUrl(JSONObject json)
	{
		if(json.containsKey(FILE_FORMAT_KEY))
		{
			fileFormat = json.get(FILE_FORMAT_KEY).isString().stringValue();
		}
	}
}
