package org.iplantc.tr.demo.server;

import java.io.IOException;
import java.net.HttpURLConnection;

import javax.servlet.http.HttpServletRequest;

/**
 * Used to establish connections to URLs.
 * 
 * @author Dennis Roberts
 */
public interface UrlConnector
{
	/**
	 * Obtains a URL connection.
	 * 
	 * @param request the servlet request.
	 * @param address the address to connect to.
	 * @return the URL connection.
	 * @throws IOException if the connection can't be established.
	 */
	public HttpURLConnection getUrlConnection(HttpServletRequest request, String address) throws IOException;
}
