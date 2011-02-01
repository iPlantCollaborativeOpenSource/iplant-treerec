package org.iplantc.tr.demo.client.utils;

import org.iplantc.tr.demo.client.services.LayoutServiceFacade;
import org.iplantc.tr.demo.client.services.TreeServices;

import com.google.gwt.json.client.JSONObject;
import com.google.gwt.user.client.rpc.AsyncCallback;


public class TreeRetriever
{
	
	public TreeRetriever()
	{
		
	}
	
	public void getSpeciesTree(String geneFamilyID, final TreeRetrieverCallBack callback)
	{
		TreeServices.getSpeciesData("pg00892", new AsyncCallback<String>()
		{
			
			@Override
			public void onSuccess(String result)
			{
				JSONObject o1 = JsonUtil.getObject(JsonUtil.getObject(result), "data");
				final String tree = JsonUtil.getObject(o1, "item").toString();
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
				
				JSONObject o1 = JsonUtil.getObject(JsonUtil.getObject(result), "data");
				JSONObject o2 = JsonUtil.getObject(o1, "item").isObject();
				final String tree = JsonUtil.getObject(o2, "gene-tree").toString();
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
	
}