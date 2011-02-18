package org.iplantc.tr.demo.client.services;

import org.iplantc.de.shared.SharedServiceFacade;
import org.iplantc.de.shared.services.ServiceCallWrapper;

import com.google.gwt.user.client.rpc.AsyncCallback;

public class TreeServices
{

	private static final String HOSTNAME = "http://votan.iplantcollaborative.org/";

	public static void getSpeciesData(String geneFamName, AsyncCallback<String> callback)
	{
		String url = HOSTNAME + "treereconciliation/get/species-data";
		if(geneFamName != null && !geneFamName.equals(""))
		{
			url = url + "/" + geneFamName;
		}
		ServiceCallWrapper wrapper = new ServiceCallWrapper(url);
		SharedServiceFacade.getInstance().getServiceData(wrapper, callback);
	}

	public static void getGeneData(String geneFamName, AsyncCallback<String> callback)
	{
		String url = HOSTNAME + "treereconciliation/get/gene-data/" + geneFamName;
		ServiceCallWrapper wrapper = new ServiceCallWrapper(url);
		SharedServiceFacade.getInstance().getServiceData(wrapper, callback);
	}

	public static void getRelationship(String body, AsyncCallback<String> callback)
	{
		String url = HOSTNAME + "treereconciliation/get/related-nodes";
		ServiceCallWrapper wrapper = new ServiceCallWrapper(ServiceCallWrapper.Type.POST, url, body);
		SharedServiceFacade.getInstance().getServiceData(wrapper, callback);
	}
	
	public static void getGeneForSpecies(String body, AsyncCallback<String> callback)
	{
		String url = HOSTNAME + "treereconciliation/get/genes-for-species";
		ServiceCallWrapper wrapper = new ServiceCallWrapper(ServiceCallWrapper.Type.POST, url, body);
		SharedServiceFacade.getInstance().getServiceData(wrapper, callback);
	}
}
