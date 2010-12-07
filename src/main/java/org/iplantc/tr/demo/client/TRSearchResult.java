package org.iplantc.tr.demo.client;

import com.extjs.gxt.ui.client.data.BaseModel;

public class TRSearchResult extends BaseModel
{
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	/**
	 * Instantiate from a result object.
	 * 
	 */
	public TRSearchResult(JsTRSearchResult jsResult)
	{		
		set("name", jsResult.getName());
		set("goAnnotations", jsResult.getGOAnnotations());
		set("numGenes", Integer.toString(jsResult.getGeneCount()));
		set("numSpecies", Integer.toString(jsResult.getSpeciesCount()));
	}

	/**
	 * Retrieve our family name.
	 * 
	 * @return family name.
	 */
	public String getName()
	{
		return get("name");
	}
	
	/**
	 * Retrieve our GO annotations.
	 * 
	 * @return GO annotations.
	 */
	public String getGoAnnotations()
	{
		return get("goAnnotations");
	}
	
	/**
	 * Retrieve our gene count.
	 * 
	 * @return number of genes.
	 */
	public String getNumGenes()
	{
		return get("numGenes");
	}
	
	/**
	 * Retrieve our species count.
	 * 
	 * @return number of species.
	 */
	public String getNumSpecies()
	{
		return get("numSpecies");
	}
}

