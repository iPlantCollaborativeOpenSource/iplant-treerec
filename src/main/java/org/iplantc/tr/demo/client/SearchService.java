package org.iplantc.tr.demo.client;

import com.google.gwt.user.client.rpc.RemoteService;
import com.google.gwt.user.client.rpc.RemoteServiceRelativePath;

/**
 * The client side stub for the RPC service.
 */
@RemoteServiceRelativePath("search")
public interface SearchService extends RemoteService
{
	String doGeneIdSearch(String term) throws IllegalArgumentException;
	String doBLASTSearch(String json) throws IllegalArgumentException;
	String doGoTermSearch(String term) throws IllegalArgumentException;
	String doGoAccessionSearch(String term) throws IllegalArgumentException;
	String getDetails(String idGeneFamily) throws IllegalArgumentException;
}
