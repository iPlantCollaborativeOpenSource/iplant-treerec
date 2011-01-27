package org.iplantc.tr.demo.server;

import org.iplantc.phyloviewer.model.BuildTreeFromJSON;
import org.iplantc.phyloviewer.model.ConvertToJSON;
import org.iplantc.phyloviewer.shared.layout.LayoutCladogram;
import org.iplantc.phyloviewer.shared.model.Tree;
import org.iplantc.tr.demo.client.services.LayoutService;
import org.json.JSONException;
import org.json.JSONObject;

import com.google.gwt.user.server.rpc.RemoteServiceServlet;

public class LayoutServiceImpl  extends RemoteServiceServlet implements LayoutService
{
	/**
	*
	*/
	private static final long serialVersionUID = -2607722375152684106L;

	@Override
	public String getLayout(String json)
	{
		try
		{
		


			JSONObject object = new JSONObject(json);
			Tree tree = BuildTreeFromJSON.buildTree(object);

			LayoutCladogram layout = new LayoutCladogram(0.8, 1.0);
			layout.setUseBranchLengths(true);
			layout.layout(tree);

			try
			{
				return ConvertToJSON.buildJSON(layout).toString();
			}
			catch(JSONException e)
			{
				return "{}";
			}

		}
		catch(JSONException e)
		{
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "{}";
		}
	}

}
