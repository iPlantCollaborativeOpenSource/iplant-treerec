package org.iplantc.tr.demo.client.services;

import org.iplantc.de.shared.SharedServiceFacade;
import org.iplantc.de.shared.services.ServiceCallWrapper;

import com.google.gwt.user.client.rpc.AsyncCallback;

public class TreeServices
{

	public static void getSpeciesData(AsyncCallback<String> callback)
	{
		String url = "http://votan.iplantcollaborative.org/treereconciliation/get/species-data";
		ServiceCallWrapper wrapper = new ServiceCallWrapper(url);
		SharedServiceFacade.getInstance().getServiceData(wrapper, callback);	
	}
	
	public static void getGeneData(String geneid, AsyncCallback<String> callback)
	{
		String url = "http://votan.iplantc.org/treereconciliation/get/gene-data/pg00892";
		ServiceCallWrapper wrapper = new ServiceCallWrapper(url);
		SharedServiceFacade.getInstance().getServiceData(wrapper, callback);	
	}

	
}
