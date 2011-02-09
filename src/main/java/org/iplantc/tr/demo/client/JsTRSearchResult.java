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
	 * Retrieve family name.
	 * 
	 * @return family name.
	 */
	public final native String getEValue() /*-{
											// evalue is only present in BLAST searches
											if (this.evalue)
											{
											return this.evalue;
											}
											else
											{
											return "";
											}
											}-*/;

	/**
	 * Retrieve family name.
	 * 
	 * @return family name.
	 */
	public final native int getAlignLength() /*-{
												// length is only present in BLAST searches
												if (this.length)
												{
												return this.length;
												}
												else
												{
												return 0;
												}
												}-*/;

	/**
	 * Retrieve family name.
	 * 
	 * @return family name.
	 */
	public final native int getGoTermCount() /*-{
												return this.goTermCount;
												}-*/;

	/**
	 * Retrieve gene count.
	 * 
	 * @return number of genes in family.
	 */
	public final native String getGeneCount() /*-{
												return this.geneCount;
												}-*/;

	/**
	 * Retrieve species count.
	 * 
	 * @return number of species in a family.
	 */
	public final native String getSpeciesCount() /*-{
													return this.speciesCount;
													}-*/;

	/**
	 * Retrieve number of duplication events.
	 * 
	 * @return number of duplication events.
	 */
	public final native String getDuplicationCount() /*-{
														return this.duplicationEvents;
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
