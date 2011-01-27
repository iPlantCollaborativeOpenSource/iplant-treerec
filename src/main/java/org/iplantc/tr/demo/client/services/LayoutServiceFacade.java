package org.iplantc.tr.demo.client.services;

import com.google.gwt.core.client.GWT;
import com.google.gwt.user.client.rpc.AsyncCallback;
import com.google.gwt.user.client.rpc.ServiceDefTarget;

public class LayoutServiceFacade
{
	private static final String SESSION_SERVICE = "layout";
	
	private static LayoutServiceFacade instance = null;
	
	private LayoutServiceAsync proxy ;
	
	
	private LayoutServiceFacade()
	{
		proxy = (LayoutServiceAsync)GWT.create(LayoutService.class);
		((ServiceDefTarget)proxy).setServiceEntryPoint(GWT.getModuleBaseURL() + SESSION_SERVICE);
	}
	
	public static LayoutServiceFacade getInstance()
	{
		if (instance == null)
		{
			instance = new LayoutServiceFacade();
		}
		
		return instance;
	}
	
	
	public void getLayout(String json, AsyncCallback<String> callback)
	{
		proxy.getLayout(json, callback);
	}
	
}
