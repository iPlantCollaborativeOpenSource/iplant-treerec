package org.iplantc.tr.demo.client.utils;

/**
 * A call back object that can be passed to TreeRetriever. 
 * The TreeRetriever will call execute method after fetching the tree and layout. 
 * 
 * @author sriram
 *
 */
public abstract class TreeRetrieverCallBack
{

	private String tree;
	
	private String layout;

	/**
	 * @param layout the layout to set
	 */
	public void setLayout(String layout)
	{
		this.layout = layout;
	}

	/**
	 * @return the layout
	 */
	public String getLayout()
	{
		return layout;
	}

	/**
	 * @param tree the tree to set
	 */
	public void setTree(String tree)
	{
		this.tree = tree;
	}

	/**
	 * @return the tree
	 */
	public String getTree()
	{
		return tree;
	}

	
	/**
	 * Call back method to be executed
	 */
	public abstract void execute();
}
