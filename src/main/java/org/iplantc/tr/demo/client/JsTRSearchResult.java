package org.iplantc.tr.demo.client;

import com.google.gwt.core.client.JavaScriptObject;

public class JsTRSearchResult extends JavaScriptObject
{
	/**
	 * Default constructor.
	 */
	protected JsTRSearchResult()
	{
	}

	/**
	 * Retrieve family name.
	 * 
	 * @return family name.
	 */
	public final native String getName() /*-{
		return this.name;
	}-*/;

	/**
	 * Retrieve gene count.
	 * 
	 * @return number of genes in family.
	 */
	public final native int getGeneCount() /*-{
		return this.geneCount;
	}-*/;

	/**
	 * Retrieve species count.
	 * 
	 * @return number of species in a family.
	 */
	public final native int getSpeciesCount() /*-{
		return this.speciesCount;
	}-*/;

	/**
	 * Retrieve GO annotations.
	 * 
	 * @return GO annotations for a family.
	 */
	public final native String getGOAnnotations() /*-{
		return this.goAnnotations;
	}-*/;
}

