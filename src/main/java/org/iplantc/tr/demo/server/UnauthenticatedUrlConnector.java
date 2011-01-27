package org.iplantc.tr.demo.server;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;

import javax.servlet.http.HttpServletRequest;

/**
 * Used to establish connections to URLs over which authentication information will not be sent.
 * 
 * @author Dennis Roberts
 */
public class UnauthenticatedUrlConnector implements UrlConnector
{
	/**
	 * {@inheritDoc}
	 */
	@Override
	public HttpURLConnection getUrlConnection(HttpServletRequest request, String address)
			throws IOException
	{
		return (HttpURLConnection)new URL(address).openConnection();
	}
}
