package org.iplantc.tr.demo.server;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URLConnection;
import java.util.List;

import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;

import org.apache.log4j.Logger;

import org.iplantc.de.shared.DEService;
import org.iplantc.de.shared.services.BaseServiceCallWrapper;
import org.iplantc.de.shared.services.HTTPPart;
import org.iplantc.de.shared.services.MultiPartServiceWrapper;
import org.iplantc.de.shared.services.ServiceCallWrapper;

import com.google.gwt.user.client.rpc.SerializationException;
import com.google.gwt.user.server.rpc.RemoteServiceServlet;

/**
 * Dispatches HTTP requests to other services.
 */
public abstract class BaseDEServiceDispatcher extends RemoteServiceServlet implements DEService
{

	private static final long serialVersionUID = 1L;
	private static final Logger LOGGER = Logger.getLogger(BaseDEServiceDispatcher.class);

	/**
	 * The servlet context to use when looking up the keystore path.
	 */
	private ServletContext context = null;

	/**
	 * The servlet request to use when building the SAML assertion.
	 */
	private HttpServletRequest request = null;

	/**
	 * Used to establish URL connections.
	 */
	private UrlConnector urlConnector;

	/**
	 * Sets the servlet context to use when looking up the keystore path.
	 * 
	 * @param context the context.
	 */
	public void setContext(ServletContext context)
	{
		this.context = context;
	}

	/**
	 * Gets the servlet context to use when looking up the keystore path.
	 * 
	 * @return an object representing a context for a servlet.
	 */
	public ServletContext getContext()
	{
		return context == null ? getServletContext() : context;
	}

	/**
	 * Sets the servlet request to use when building the SAML assertion.
	 * 
	 * @param request the request to use.
	 */
	public void setRequest(HttpServletRequest request)
	{
		this.request = request;
	}

	/**
	 * Gets the servlet request to use when building the SAML assertion.
	 * 
	 * @return the request to use.
	 */
	public HttpServletRequest getRequest()
	{
		return request == null ? getThreadLocalRequest() : request;
	}

	/**
	 * Sets the URL connector for this service dispatcher. This connector should be set once when the
	 * object is created.
	 * 
	 * @param urlConnector the new URL connector.
	 */
	protected void setUrlConnector(UrlConnector urlConnector)
	{
		this.urlConnector = urlConnector;
	}

	/**
	 * Retrieves the result from a URL connection.
	 * 
	 * @param urlc the URL connection.
	 * @return the URL result as a string.
	 * @throws UnsupportedEncodingException if UTF-8 isn't supported.
	 * @throws IOException if an I/O error occurs.
	 */
	private String retrieveResult(URLConnection urlc) throws UnsupportedEncodingException, IOException
	{
		StringBuffer buffer = new StringBuffer();
		BufferedReader br = null;
		try
		{
			br = new BufferedReader(new InputStreamReader(urlc.getInputStream(), "UTF-8"));

			while(true)
			{
				int ch = br.read();

				if(ch < 0)
				{
					break;
				}

				buffer.append((char)ch);
			}
		}
		finally
		{
			if(br != null)
			{
				br.close();
			}
		}

		return buffer.toString();
	}

	/**
	 * Obtains a URL connection.
	 * 
	 * @param address the address to connect to.
	 * @return the URL connection.
	 * @throws IOException if the connection can't be established.
	 */
	protected HttpURLConnection getUrlConnection(String address) throws IOException
	{
		if(urlConnector == null)
		{
			throw new IOException("No URL connector available.");
		}
		return urlConnector.getUrlConnection(getRequest(), address);
	}

	/**
	 * Sends an HTTP GET request to another service.
	 * 
	 * @param address the address to connect to.
	 * @return the URL connection used to send the request.
	 * @throws IOException if an error occurs.
	 */
	private URLConnection get(String address) throws IOException
	{
		if(LOGGER.isDebugEnabled())
		{
			LOGGER.debug("sending a GET request to " + address);
		}

		// make post mode connection
		URLConnection urlc = getUrlConnection(address);
		urlc.setDoOutput(true);

		LOGGER.debug("GET request sent to " + address);

		return urlc;
	}

	/**
	 * Sends an HTTP UPDATE request to another service.
	 * 
	 * @param address the address to connect to.
	 * @param body the request body.
	 * @param requestMethod the request method.
	 * @return the URL connection used to send the request.
	 * @throws IOException if an I/O error occurs.
	 */
	private URLConnection update(String address, String body, String requestMethod) throws IOException
	{
		if(LOGGER.isDebugEnabled())
		{
			LOGGER.debug("sending an UPDATE request to " + address);
		}

		// make post mode connection
		HttpURLConnection urlc = getUrlConnection(address);
		urlc.setRequestMethod(requestMethod);
		urlc.setDoOutput(true);

		// send post
		OutputStreamWriter outRemote = null;
		try
		{
			outRemote = new OutputStreamWriter(urlc.getOutputStream());
			outRemote.write(body);
			outRemote.flush();
		}
		finally
		{
			if(outRemote != null)
			{
				outRemote.close();
			}
		}

		LOGGER.debug("UPDATE request sent");

		return urlc;
	}

	/**
	 * Creates the MIME content type for the given multipart boundary.
	 * 
	 * @param boundary the MIME multipart boundary.
	 * @return the content type.
	 */
	private String getContentType(String boundary)
	{
		return "multipart/form-data; boundary=" + boundary;
	}

	/**
	 * Builds a MIME multiparty boundary.
	 * 
	 * @return the boundary.
	 */
	private String buildBoundary()
	{
		return "--------------------" + Long.toString(System.currentTimeMillis(), 16);
	}

	/**
	 * Sends a multipart HTTP update request to another service.
	 * 
	 * @param address the address to send the request to.
	 * @param parts the components of the multipart request.
	 * @param requestMethod the request method.
	 * @return the URL connection used to send the request.
	 * @throws IOException if an I/O error occurs.
	 */
	private URLConnection updateMultipart(String address, List<HTTPPart> parts, String requestMethod)
			throws IOException
	{
		if(LOGGER.isDebugEnabled())
		{
			LOGGER.debug("sending a multipart UPDATE request to " + address);
		}

		String boundary = buildBoundary();

		// make post mode connection
		HttpURLConnection urlc = getUrlConnection(address);
		urlc.setRequestProperty("content-type", getContentType(boundary));
		urlc.setRequestMethod(requestMethod);
		urlc.setDoOutput(true);

		// send post
		DataOutputStream outRemote = null;
		try
		{
			outRemote = new DataOutputStream(urlc.getOutputStream());
			for(HTTPPart part : parts)
			{
				outRemote.writeBytes("--" + boundary);
				outRemote.writeBytes("\n");
				outRemote.writeBytes("Content-Disposition: form-data; " + part.getDisposition());
				outRemote.writeBytes("\r\n\r\n");
				outRemote.writeBytes(part.getBody());
				outRemote.writeBytes("\r\n--" + boundary + "--\r\n");
			}

			outRemote.flush();
			outRemote.close();
		}
		finally
		{
			if(outRemote != null)
			{
				outRemote.close();
			}
		}

		LOGGER.debug("multipart UPDATE request sent");

		return urlc;
	}

	/**
	 * Sends an HTTP DELETE request to another service.
	 * 
	 * @param address the address to send the request to.
	 * @return the URL connection used to send the request.
	 * @throws IOException if an I/O error occurs.
	 */
	private URLConnection delete(String address) throws IOException
	{
		// make post mode connection
		HttpURLConnection urlc = getUrlConnection(address);

		urlc.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
		urlc.setRequestMethod("DELETE");
		urlc.setDoOutput(true);
		urlc.connect();

		return urlc;
	}

	/**
	 * Verifies that a string is not null or empty.
	 * 
	 * @param in the string to validate.
	 * @return true if the string is not null or empty.
	 */
	private boolean isValidString(String in)
	{
		return (in != null && in.length() > 0);
	}

	/**
	 * Validates a service call wrapper. The address must be a non-empty string for all HTTP requests.
	 * The message body must be a non-empty string for PUT and POST requests.
	 * 
	 * @param wrapper the service call wrapper being validated.
	 * @return true if the service call wrapper is valid.
	 */
	private boolean isValidServiceCall(ServiceCallWrapper wrapper)
	{
		boolean ret = false; // assume failure

		if(wrapper != null)
		{
			if(isValidString(wrapper.getAddress()))
			{
				switch (wrapper.getType())
				{
					case GET:
					case DELETE:
						ret = true;
						break;

					case PUT:
					case POST:
						if(isValidString(wrapper.getBody()))
						{
							ret = true;
						}
						break;

					default:
						break;
				}
			}
		}

		return ret;
	}

	/**
	 * Validates a multi-part service call wrapper. The address must not be null or empty and the message
	 * body must have at least one part.
	 * 
	 * @param wrapper the wrapper to validate.
	 * @return true if the service call wrapper is valid.
	 */
	private boolean isValidServiceCall(MultiPartServiceWrapper wrapper)
	{
		boolean ret = false; // assume failure

		if(wrapper != null)
		{
			if(isValidString(wrapper.getAddress()))
			{
				switch (wrapper.getType())
				{
					case PUT:
					case POST:
						if(wrapper.getNumParts() > 0)
						{
							ret = true;
						}
						break;

					default:
						break;
				}
			}
		}

		return ret;
	}

	/**
	 * Retrieve the service address for the wrapper.
	 * 
	 * @param service call wrapper containing metadata for a call.
	 * @return a string representing a valid URL.
	 */
	private String retrieveServiceAddress(BaseServiceCallWrapper wrapper)
	{
		String address = wrapper.getAddress();
		if(wrapper.hasArguments())
		{
			String args = wrapper.getArguments();
			address += (args.startsWith("?")) ? args : "?" + args;
		}
		return address;
	}

	/**
	 * Implements entry point for service dispatcher.
	 * 
	 * @param wrapper the service call wrapper.
	 * @return the response from the service call.
	 * @throws SerializationException if an error occurs.
	 */
	public String getServiceData(ServiceCallWrapper wrapper) throws SerializationException
	{
		String json = null;
		URLConnection urlc = null;

		if(isValidServiceCall(wrapper))
		{
			String address = retrieveServiceAddress(wrapper);
			String body = wrapper.getBody();
			System.out.println("request json==>" + body);
			try
			{
				switch (wrapper.getType())
				{
					case GET:
						urlc = get(address);
						break;

					case PUT:
						urlc = update(address, body, "PUT");
						break;

					case POST:
						urlc = update(address, body, "POST");
						break;

					case DELETE:
						urlc = delete(address);
						break;

					default:
						break;
				}

				json = retrieveResult(urlc);
			}
			catch(Exception ex)
			{
				LOGGER.error(ex.toString(), ex);
				// because the GWT compiler will issue a warning if we simply
				// throw exception, we'll
				// use SerializationException()
				throw new SerializationException(ex);
			}
		}

		LOGGER.debug("json==>" + json);
		System.out.println("json==>" + json);
		return json;
	}

	/**
	 * Implements entry point for service dispatcher for streaming data back to client.
	 * 
	 * @param wrapper the service call wrapper.
	 * @return an input stream that can be used to retrieve the response from the service call.
	 * @throws IOException if an I/O error occurs.
	 * @throws SerializationException if any other error occurs.
	 */
	public DEServiceInputStream getServiceStream(ServiceCallWrapper wrapper)
			throws SerializationException, IOException
	{
		String json = null;
		URLConnection urlc = null;

		if(isValidServiceCall(wrapper))
		{
			String address = retrieveServiceAddress(wrapper);
			String body = wrapper.getBody();

			try
			{
				switch (wrapper.getType())
				{
					case GET:
						urlc = get(address);
						break;

					case PUT:
						urlc = update(address, body, "PUT");
						break;

					case POST:
						urlc = update(address, body, "POST");
						break;

					case DELETE:
						urlc = delete(address);
						break;

					default:
						break;
				}
			}
			catch(Exception ex)
			{
				// because the GWT compiler will issue a warning if we simply
				// throw exception, we'll
				// use SerializationException()
				throw new SerializationException(ex);
			}
		}

		LOGGER.debug("json==>" + json);
		System.out.println("json==>" + json);
		return new DEServiceInputStream(urlc);
	}

	/**
	 * Sends a multi-part HTTP PUT or POST request to another service and returns the response.
	 * 
	 * @param wrapper the service call wrapper.
	 * @return the response to the HTTP request.
	 * @throws SerializationException if an error occurs.
	 */
	public String getServiceData(MultiPartServiceWrapper wrapper) throws SerializationException
	{
		String json = null;
		URLConnection urlc = null;

		if(isValidServiceCall(wrapper))
		{
			String address = retrieveServiceAddress(wrapper);
			List<HTTPPart> parts = wrapper.getParts();

			try
			{
				switch (wrapper.getType())
				{
					case PUT:
						urlc = updateMultipart(address, parts, "PUT");
						break;

					case POST:
						urlc = updateMultipart(address, parts, "POST");
						break;

					default:
						break;
				}

				json = retrieveResult(urlc);
			}
			catch(Exception ex)
			{
				// because the GWT compiler will issue a warning if we simply
				// throw exception, we'll
				// use SerializationException()
				throw new SerializationException(ex);
			}
		}

		System.out.println("json==>" + json);
		return json;
	}
}
