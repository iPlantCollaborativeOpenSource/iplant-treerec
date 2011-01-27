package org.iplantc.tr.demo.client.services;

import com.google.gwt.user.client.rpc.AsyncCallback;

public interface LayoutServiceAsync
{

	void getLayout(String json, AsyncCallback<String> callback);

}
