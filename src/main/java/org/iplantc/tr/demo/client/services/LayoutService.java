package org.iplantc.tr.demo.client.services;

import com.google.gwt.user.client.rpc.RemoteService;

public interface LayoutService extends RemoteService
{
	String getLayout(String json);
}
