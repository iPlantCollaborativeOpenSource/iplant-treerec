package org.iplantc.tr.demo.client;

import com.google.gwt.user.client.rpc.AsyncCallback;

/**
 * The async counterpart of <code>GreetingService</code>.
 */
public interface SearchServiceAsync
{
	void doGeneIdSearch(String term, AsyncCallback<String> callback) throws IllegalArgumentException;
	void doBLASTSearch(String json, AsyncCallback<String> callback) throws IllegalArgumentException;
	void doGoTermSearch(String term, AsyncCallback<String> callback) throws IllegalArgumentException;
	void doGoAccessionSearch(String term, AsyncCallback<String> callback) throws IllegalArgumentException;
	void getDetails(String idGeneFamily, AsyncCallback<String> callback) throws IllegalArgumentException;
	void getSummary(String idGeneFamily, AsyncCallback<String> callback) throws IllegalArgumentException;
}
