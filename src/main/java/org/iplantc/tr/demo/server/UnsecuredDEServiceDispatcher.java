package org.iplantc.tr.demo.server;

/**
 * A dispatch service servlet that all client-side service facade make "unsecured" requests regarding
 * data that is not sensitive.
 */
public class UnsecuredDEServiceDispatcher extends BaseDEServiceDispatcher
{
	private static final long serialVersionUID = 1L;

	/**
	 * Initializes the new service dispatcher.
	 */
	public UnsecuredDEServiceDispatcher()
	{
		setUrlConnector(new UnauthenticatedUrlConnector());
	}
}
