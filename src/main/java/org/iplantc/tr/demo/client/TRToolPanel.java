package org.iplantc.tr.demo.client;

import java.util.List;

import com.extjs.gxt.ui.client.event.ButtonEvent;
import com.extjs.gxt.ui.client.event.ComponentEvent;
import com.extjs.gxt.ui.client.event.KeyListener;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.widget.Component;
import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.extjs.gxt.ui.client.widget.HorizontalPanel;
import com.extjs.gxt.ui.client.widget.Label;
import com.extjs.gxt.ui.client.widget.LayoutContainer;
import com.extjs.gxt.ui.client.widget.MessageBox;
import com.extjs.gxt.ui.client.widget.Status;
import com.extjs.gxt.ui.client.widget.VerticalPanel;
import com.extjs.gxt.ui.client.widget.button.Button;
import com.extjs.gxt.ui.client.widget.form.TextArea;
import com.extjs.gxt.ui.client.widget.form.TextField;
import com.google.gwt.core.client.JsArray;
import com.google.gwt.event.dom.client.ChangeEvent;
import com.google.gwt.event.dom.client.ChangeHandler;
import com.google.gwt.event.dom.client.KeyCodes;
import com.google.gwt.user.client.rpc.AsyncCallback;
import com.google.gwt.user.client.ui.ListBox;
import com.google.gwt.user.client.ui.Widget;

public class TRToolPanel extends VerticalPanel
{
	private static final String TR_SEARCH_TYPE_LIST_BOX_ID = "idTRSearchTypeSelection";

	private static final String SEARCH_TYPE_BLAST = "blast";
	private static final String SEARCH_TYPE_GENE_NAME = "gene_name";
	private static final String SEARCH_TYPE_GO = "go";
	private static final String SEARCH_TYPE_FAMILY_ID = "family_id";

	private final int GRID_HEIGHT_NORMAL = 260;
	private final int GRID_HEIGHT_SHORT = 142;

	private ListBox selectSearchType;

	private ContentPanel pnlSearch;

	private SimpleSearchPanel pnlSearchGeneName;
	private SimpleSearchPanel pnlSearchGO;
	private SimpleSearchPanel pnlSearchFamilyId;

	private BLASTSearchPanel pnlSearchBlast;

	private HorizontalPanel pnlButtons;
	private Button searchButton;
	private Button cancelButton;
	private Status waitIcon;

	private SearchServiceAsync searchService;
	private ClientCommand cmdView;
	private ClientCommand cmdSearchBegin;
	private ClientCommand cmdSearchComplete;

	public TRToolPanel(SearchServiceAsync searchService, ClientCommand cmdView,
			ClientCommand cmdSearchBegin, ClientCommand cmdSearchComplete)
	{
		this.searchService = searchService;
		this.cmdView = cmdView;
		this.cmdSearchBegin = cmdSearchBegin;
		this.cmdSearchComplete = cmdSearchComplete;

		init();

		compose();
	}

	private void init()
	{
		waitIcon = new Status();
		buildButtonPanel();
	}

	/**
	 * Removes all search panels from this panel
	 * 
	 * @param pnl
	 */
	private void removeSearchPanelFromLayoutContainer(LayoutContainer pnl)
	{
		List<Component> components = pnl.getItems();

		for(Component component : components)
		{
			if(component instanceof SearchPanel)
			{
				pnl.remove(component);
				break;
			}
		}
	}

	private void showTextFieldSearchInput()
	{
		removeSearchPanelFromLayoutContainer(pnlSearch);
		SearchPanel searchPanel = getCurrentSearchPanel();
		pnlSearch.add(searchPanel);
		pnlSearch.layout();

		searchPanel.setFocusWidget();
	}

	private SearchPanel getCurrentSearchPanel()
	{
		String type = selectSearchType.getValue(selectSearchType.getSelectedIndex());

		if(type.equals(SEARCH_TYPE_GENE_NAME))
		{
			return pnlSearchGeneName;
		}
		else if(type.equals(SEARCH_TYPE_BLAST))
		{
			return pnlSearchBlast;
		}
		else if(type.equals(SEARCH_TYPE_GO))
		{
			return pnlSearchGO;
		}
		else if(type.equals(SEARCH_TYPE_FAMILY_ID))
		{
			return pnlSearchFamilyId;
		}
		else
		{
			return null;
		}
	}

	private void showTextAreaSearchInput()
	{
		removeSearchPanelFromLayoutContainer(pnlSearch);
		pnlSearch.add(pnlSearchBlast);
		pnlSearch.layout();

		pnlSearchBlast.setFocusWidget();
	}

	private void updateSelection()
	{
		String value = selectSearchType.getValue(selectSearchType.getSelectedIndex());

		if(value.equals(SEARCH_TYPE_BLAST))
		{
			showTextAreaSearchInput();
		}
		else
		{
			showTextFieldSearchInput();
		}
	}

	private ListBox initSearchTypeSelection()
	{
		ListBox ret = new ListBox();

		ret.getElement().setId(TR_SEARCH_TYPE_LIST_BOX_ID);

		ret.addItem("BLAST", SEARCH_TYPE_BLAST);
		ret.addItem("Gene Name", SEARCH_TYPE_GENE_NAME);
		ret.addItem("Gene Ontology", SEARCH_TYPE_GO);
		ret.addItem("Gene Family ID", SEARCH_TYPE_FAMILY_ID);

		// handle selection changed
		ret.addChangeHandler(new ChangeHandler()
		{
			@Override
			public void onChange(ChangeEvent ce)
			{
				updateSelection();
			}
		});

		return ret;
	}

	private VerticalPanel buildSearchTypeSelectionPanel()
	{
		VerticalPanel ret = new VerticalPanel();

		selectSearchType = initSearchTypeSelection();

		ret.add(new Label("Select appropriate search type:"));
		ret.add(selectSearchType);

		return ret;
	}

	private void performGeneIdSearch(final String term)
	{
		if(searchService != null && term != null)
		{
			pnlSearchGeneName.searchBegin();
			searchService.doGeneIdSearch(term, pnlSearchGeneName.getSearchCallback(term));
		}
	}

	private void performGoTermSearch(final String term)
	{
		if(term != null)
		{
			pnlSearchGO.searchBegin();
			searchService.doGoTermSearch(term, pnlSearchGO.getSearchCallback(term));
		}
	}

	private void performGoAccessionSearch(final String term)
	{
		if(term != null)
		{
			pnlSearchFamilyId.searchBegin();
			searchService.getDetails(term, pnlSearchFamilyId.getSearchCallback(term));
		}
	}

	private String buildBLASTJson()
	{
		String ret = "{";

		// XXX delete me
		ret += "\"sequenceType\": \"protein\",";

		ret += "\"sequence\": \"" + JsonUtil.escapeNewLine(pnlSearchBlast.getSearchTerms()) + "\"";

		ret += "}";

		return ret;
	}

	private void performBLASTSearch(final String term)
	{
		String json = buildBLASTJson();

		pnlSearchBlast.searchBegin();
		searchService.doBLASTSearch(json, pnlSearchBlast.getSearchCallback());
	}

	private Button buildSearchButton()
	{
		Button btn = PanelHelper.buildButton("idTRSearchBtn", "Search",
				new SelectionListener<ButtonEvent>()
				{
					@Override
					public void componentSelected(ButtonEvent ce)
					{
						String type = selectSearchType.getValue(selectSearchType.getSelectedIndex());

						if(type.equals(SEARCH_TYPE_GENE_NAME))
						{
							performGeneIdSearch(pnlSearchGeneName.getSearchTerm());
						}
						else if(type.equals(SEARCH_TYPE_BLAST))
						{
							performBLASTSearch(pnlSearchBlast.getSearchTerms());
						}
						else if(type.equals(SEARCH_TYPE_GO))
						{
							performGoTermSearch(pnlSearchGO.getSearchTerm());
						}
						else if(type.equals(SEARCH_TYPE_FAMILY_ID))
						{
							performGoAccessionSearch(pnlSearchFamilyId.getSearchTerm());
						}
					}
				});
		btn.setEnabled(false);
		return btn;
	}

	private ContentPanel initSearchPanel()
	{
		ContentPanel ret = new ContentPanel();
		ret.setHeaderVisible(false);
		ret.setBodyStyle("backgroundColor: #EDEDED");
		ret.setWidth(382);
		ret.setHeight(159);

		pnlSearchGeneName = new SimpleSearchPanel("Enter the name of the gene of interest:");
		pnlSearchGO = new SimpleSearchPanel(
				"Enter GO term to query (can be accession number or one or multiple terms):");
		pnlSearchFamilyId = new SimpleSearchPanel("Enter Gene Family ID (internal identifier):");
		pnlSearchBlast = new BLASTSearchPanel();

		ret.add(buildSearchTypeSelectionPanel());
		ret.add(pnlSearchBlast);

		return ret;
	}

	private void compose()
	{
		pnlSearch = initSearchPanel();

		ContentPanel pnlInner = new ContentPanel();
		pnlInner.setHeaderVisible(false);
		pnlInner.setTopComponent(pnlSearch);
		pnlInner.setBottomComponent(pnlButtons);
		add(pnlInner);
	}

	public Widget getFocusWidget()
	{
		return getCurrentSearchPanel().getFocusWidget();
	}

	/**
	 * Builds the search and cancel buttons and the search panel
	 */
	private void buildButtonPanel()
	{
		searchButton = buildSearchButton();
		cancelButton = buildCancelButton();

		pnlButtons = new HorizontalPanel();
		pnlButtons.setStyleAttribute("background-color", "#EDEDED");
		pnlButtons.setSpacing(5);
		pnlButtons.add(cancelButton);
		pnlButtons.add(searchButton);
		pnlButtons.add(waitIcon);
	}

	private Button buildCancelButton()
	{
		Button btn = PanelHelper.buildButton("idTRCancelBtn", "Cancel",
				new SelectionListener<ButtonEvent>()
				{
					@Override
					public void componentSelected(ButtonEvent ce)
					{
						getCurrentSearchPanel().searchComplete();
					}
				});
		btn.disable();
		return btn;
	}

	abstract class SearchPanel extends VerticalPanel
	{

		abstract void setFocusWidget();

		abstract Widget getFocusWidget();

		void searchBegin()
		{
			waitIcon.setBusy("Working");
			searchButton.disable();
			cancelButton.enable();
		}

		void searchComplete()
		{
			cancelButton.disable();
			searchButton.enable();
			waitIcon.clearStatus("");
		}
	}

	// simple search panel - contains text field and search button
	class SimpleSearchPanel extends SearchPanel
	{
		private static final String TR_SEARCH_FIELD_ID = "idTRSearchField";

		private TextField<String> entrySearch;
		private String searchLabel;

		public SimpleSearchPanel(String searchLabel)
		{
			init(searchLabel);
			compose();
		}

		private void init(String searchLabel)
		{
			this.searchLabel = searchLabel;
			entrySearch = buildSearchEntry();
		}

		private void compose()
		{
			VerticalPanel panelInner = new VerticalPanel();
			panelInner.add(new Label(searchLabel));

			panelInner.add(entrySearch);

			add(panelInner);
		}

		private TextField<String> buildSearchEntry()
		{
			final TextField<String> ret = new TextField<String>();

			ret.setId(TR_SEARCH_FIELD_ID);
			ret.setWidth(290);
			ret.setSelectOnFocus(true);
			ret.addKeyListener(new KeyListener()
			{
				public void componentKeyUp(ComponentEvent event)
				{
					String text = ret.getValue();
					if(event.getKeyCode() == KeyCodes.KEY_ENTER)
					{
						performGeneIdSearch(text);
					}
					searchButton.setEnabled(text != null && !text.isEmpty());
				}
			});

			return ret;
		}

		public String getSearchTerm()
		{
			return entrySearch.getValue();
		}

		public void setFocusWidget()
		{
			if(entrySearch != null)
			{
				entrySearch.focus();
			}
		}

		public TextField<String> getFocusWidget()
		{
			return entrySearch;
		}

		public AsyncCallback<String> getSearchCallback(final String term)
		{
			return new AsyncCallback<String>()
			{
				@Override
				public void onFailure(Throwable arg0)
				{
					searchComplete();

					String err = "Search failed for term: " + term;
					MessageBox.alert("Error", err, null);
				}

				@Override
				public void onSuccess(String result)
				{
					// show results unless the search has been cancelled
					if(cancelButton.isEnabled())
					{
						searchComplete();
						String value = selectSearchType.getValue(selectSearchType.getSelectedIndex());
						searchComplete();
						if(value.equals(SEARCH_TYPE_FAMILY_ID))
						{
							showTreeViewer(result);
						}
						else
						{
							showSimpleResultsWindow("Results for term " + term + ":", result);
						}
					}
				}
			};
		}
	}

	// BLAST search panel - contains text area, search button and fields for supported
	// BLAST search params
	class BLASTSearchPanel extends SearchPanel
	{
		private static final String TR_BLAST_SEARCH_AREA_ID = "idTRSearchField";

		private SearchTextArea areaSearch;

		public BLASTSearchPanel()
		{
			init();

			compose();
		}

		private SearchTextArea buildSearchArea()
		{
			final SearchTextArea ret = new SearchTextArea();

			ret.setSize(380, 99);
			ret.setSelectOnFocus(true);
			ret.setId(TR_BLAST_SEARCH_AREA_ID);
			ret.addKeyListener(new KeyListener()
			{
				public void componentKeyUp(ComponentEvent event)
				{
					String text = ret.getValue();
					searchButton.setEnabled(text != null && !text.isEmpty());
				}
			});

			return ret;
		}

		private void init()
		{
			areaSearch = buildSearchArea();
		}

		private void compose()
		{
			// add type selection
			add(new Label("Enter protein or nucleotide sequence for gene of interest below:"));

			// add search components
			add(areaSearch);
		}

		public String getSearchTerms()
		{
			return areaSearch.getValue();
		}

		public void setFocusWidget()
		{
			if(areaSearch != null)
			{
				areaSearch.focus();
			}
		}

		public SearchTextArea getFocusWidget()
		{
			return areaSearch;
		}

		public AsyncCallback<String> getSearchCallback()
		{
			return new AsyncCallback<String>()
			{
				@Override
				public void onFailure(Throwable arg0)
				{
					searchComplete();

					String err = "Search failed for term: " + pnlSearchBlast.getSearchTerms();
					MessageBox.alert("Error", err, null);
				}

				@Override
				public void onSuccess(String result)
				{
					// show results unless the search has been cancelled
					if(cancelButton.isEnabled())
					{
						searchComplete();
						showBlastResultsWindow("Results for BLAST search for entered sequence:", result);
					}
				}
			};
		}

		class SearchTextArea extends TextArea
		{
			@Override
			protected void afterRender()
			{
				super.afterRender();

				el().setElementAttribute("spellcheck", "false");
			}
		}
	}

	private void showSimpleResultsWindow(String heading, String results)
	{
		new TRSearchResultsWindow(heading, results, false, cmdView).show();
	}

	private void showBlastResultsWindow(String heading, String results)
	{
		new TRSearchResultsWindow(heading, results, true, cmdView).show();
	}

	private void showTreeViewer(String result)
	{
		JsArray<JsTRSearchResult> arr = TRUtil.parseFamilies(result);
		if(arr != null && arr.length() > 0)
			cmdView.execute(arr.get(0).getName());
		System.out.println("fam id search result = " + result);
	}
}
