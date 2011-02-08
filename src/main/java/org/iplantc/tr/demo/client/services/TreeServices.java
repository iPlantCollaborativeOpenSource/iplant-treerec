package org.iplantc.tr.demo.client.services;

import org.iplantc.de.shared.SharedServiceFacade;
import org.iplantc.de.shared.services.ServiceCallWrapper;

import com.google.gwt.user.client.rpc.AsyncCallback;

public class TreeServices
{
	
	private static String hostname = "http://votan.iplantcollaborative.org/treereconciliation";

	public static void getSpeciesData(String geneFamName, AsyncCallback<String> callback)
	{
	
		String url = hostname + "/get/species-data";
		if (geneFamName != null && !geneFamName.equals(""))
		{
			url = url + "/" + geneFamName;
		}
		ServiceCallWrapper wrapper = new ServiceCallWrapper(url);
		SharedServiceFacade.getInstance().getServiceData(wrapper, callback);	
	}
	
	public static void getGeneData(String geneFamName, AsyncCallback<String> callback)
	{
		String url = hostname + "/get/gene-data/" + geneFamName;
		ServiceCallWrapper wrapper = new ServiceCallWrapper(url);
		SharedServiceFacade.getInstance().getServiceData(wrapper, callback);	
	}

	public static void getRelatedGeneEdgeNode(String body, AsyncCallback<String> callback)
	{
		String url = hostname + "/get/related-nodes";
		ServiceCallWrapper wrapper = new ServiceCallWrapper(ServiceCallWrapper.Type.POST,url,body);
		SharedServiceFacade.getInstance().getServiceData(wrapper, callback);	
	}
	
	public static void getRelatedSpeciesEdgeNode(String body, AsyncCallback<String> callback)
	{
		String url = hostname + "/get/related-nodes";
		ServiceCallWrapper wrapper = new ServiceCallWrapper(ServiceCallWrapper.Type.POST,url,body);
		SharedServiceFacade.getInstance().getServiceData(wrapper, callback);	
	}
}
