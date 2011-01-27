package org.iplantc.tr.demo.client.utils;

import org.iplantc.tr.demo.client.services.LayoutServiceFacade;
import org.iplantc.tr.demo.client.services.TreeServices;

import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
import com.google.gwt.user.client.rpc.AsyncCallback;


public class TreeRetriever
{
	
	public TreeRetriever()
	{
		
	}
	
	public void getSpeciesTree(String geneFamilyID, final TreeRetrieverCallBack callback)
	{
		TreeServices.getSpeciesData(new AsyncCallback<String>()
		{
			
			@Override
			public void onSuccess(String result)
			{
				final String tree = parseTreeJson(result) ;
				if (tree != null)
				{
					LayoutServiceFacade.getInstance().getLayout(tree, new AsyncCallback<String>()
					{
	
						@Override
						public void onFailure(Throwable caught)
						{
							System.out.println(caught.toString());
							
						}
	
						@Override
						public void onSuccess(String result)
						{
							callback.setLayout(result);
							callback.setTree(tree);
							callback.execute();
						}
					});
				}
			}
			@Override
			public void onFailure(Throwable caught)
			{
				System.out.println(caught.toString());
				
			}
		});
	}
	
	public void getGeneTree(String geneFamilyID, final TreeRetrieverCallBack callback)
	{
		TreeServices.getGeneData("pg00892", new AsyncCallback<String>()
		{

			@Override
			public void onFailure(Throwable caught)
			{
				System.out.println(caught.toString());
				
			}

			@Override
			public void onSuccess(String result)
			{
				
				final String tree = parseTreeJson(result) ;
				if (tree != null)
				{
					LayoutServiceFacade.getInstance().getLayout(tree, new AsyncCallback<String>()
					{
	
						@Override
						public void onFailure(Throwable caught)
						{
							System.out.println(caught.toString());
							
						}
	
						@Override
						public void onSuccess(String result)
						{
							callback.setLayout(result);
							callback.setTree(tree);
							callback.execute();
						}
					});
				}
			}
		});
	}
	
	private String parseTreeJson (String json)
	{
		String tree = null;
		JSONObject obj = JSONParser.parseStrict(json).isObject();
		if (obj != null)
		{
			final JSONObject obj1 = obj.get("data").isObject();
			if(obj1 != null)
			{
				tree = obj1.get("item").toString();
			}
		}
		
		return tree;
	}
	
}