package org.iplantc.tr.demo.client.panels;

import java.util.List;

import org.iplantc.tr.demo.client.commands.ClientCommand;
import org.iplantc.tr.demo.client.services.SearchServiceAsync;
import org.iplantc.tr.demo.client.utils.JsonUtil;
import org.iplantc.tr.demo.client.utils.TRUtil;
import org.iplantc.tr.demo.client.windows.TRSearchResultsWindow;

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
import com.google.gwt.event.dom.client.ChangeEvent;
import com.google.gwt.event.dom.client.ChangeHandler;
import com.google.gwt.event.dom.client.KeyCodes;
import com.google.gwt.json.client.JSONArray;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONString;
import com.google.gwt.user.client.rpc.AsyncCallback;
import com.google.gwt.user.client.ui.ListBox;
import com.google.gwt.user.client.ui.Widget;

/**
 * Interface for providing the user advanced search options.
 * 
 * @author amuir
 * 
 */
public class TRAdvancedSearchPanel extends ContentPanel
{
	private static final String TR_SEARCH_TYPE_LIST_BOX_ID = "idTRSearchTypeSelection";

	private static final String SEARCH_TYPE_BLAST = "blast";
	private static final String SEARCH_TYPE_GENE_NAME = "gene_name";
	private static final String SEARCH_TYPE_GO = "go";
	private static final String SEARCH_TYPE_FAMILY_ID = "family_id";

	private ListBox selectSearchType;

	private VerticalPanel pnlSearch;

	private SimpleSearchPanel pnlSearchGeneName;
	private SimpleSearchPanel pnlSearchGO;
	private SimpleSearchPanel pnlSearchFamilyId;

	private BLASTSearchPanel pnlSearchBlast;

	private SearchServiceAsync searchService;
	private ClientCommand cmdView;

	/**
	 * Instantiate from a search service and a view command.
	 * 
	 * @param searchService service for searching.
	 * @param cmdView passed through to the search results window.
	 */
	public TRAdvancedSearchPanel(SearchServiceAsync searchService, ClientCommand cmdView)
	{
		this.searchService = searchService;
		this.cmdView = cmdView;

		init();

		compose();
	}

	private void init()
	{
		setBorders(false);
		setBodyBorder(false);
		setHeaderVisible(false);
		setSize(402, 214);
		setBodyStyle("background-color: #EDEDED");
		setStyleAttribute("background-color", "#EDEDED");
	}

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
		SearchPanel ret = null; // assume failure

		String type = selectSearchType.getValue(selectSearchType.getSelectedIndex());

		if(type.equals(SEARCH_TYPE_GENE_NAME))
		{
			ret = pnlSearchGeneName;
		}
		else if(type.equals(SEARCH_TYPE_BLAST))
		{
			ret = pnlSearchBlast;
		}
		else if(type.equals(SEARCH_TYPE_GO))
		{
			ret = pnlSearchGO;
		}
		else if(type.equals(SEARCH_TYPE_FAMILY_ID))
		{
			ret = pnlSearchFamilyId;
		}

		return ret;
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

		ret.setStyleAttribute("background-color", "#EDEDED");
		ret.setStyleAttribute("margin-left", "5px");

		selectSearchType = initSearchTypeSelection();

		ret.add(new Label("Search type:"));
		ret.add(selectSearchType);

		return ret;
	}

	private void performSearch()
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
			searchService.getSummary(term, pnlSearchFamilyId.getSearchCallback(term));
		}
	}

	private String buildBLASTJson()
	{
		String ret = "{";

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

	private VerticalPanel initSearchPanel()
	{
		VerticalPanel ret = new VerticalPanel();
		ret.setSize(382, 159);
		ret.setBorders(false);
		ret.setSpacing(5);
		ret.setStyleAttribute("background-color", "#EDEDED");

		pnlSearchGeneName = new SimpleSearchPanel("Gene of interest:");
		pnlSearchGO =
				new SimpleSearchPanel(
						"GO term to query (can be accession number or one or multiple terms):");

		pnlSearchFamilyId = new SimpleSearchPanel("Gene Family ID (internal identifier):");

		pnlSearchBlast = new BLASTSearchPanel();

		ret.add(buildSearchTypeSelectionPanel());
		ret.add(pnlSearchBlast);

		pnlSearchBlast.setFocusWidget();

		return ret;
	}

	private void compose()
	{
		pnlSearch = initSearchPanel();

		add(pnlSearch);
	}

	public Widget getFocusWidget()
	{
		return getCurrentSearchPanel().getFocusWidget();
	}

	abstract class SearchPanel extends VerticalPanel
	{
		protected Button btnSearch;
		protected Status waitIcon;

		protected abstract void setFocusWidget();

		protected abstract Widget getFocusWidget();

		private SearchPanel()
		{
			setSpacing(5);
		}

		private Button buildSearchButton()
		{
			Button btn =
					PanelHelper.buildButton("idTRSearchBtn", "Search",
							new SelectionListener<ButtonEvent>()
							{
								@Override
								public void componentSelected(ButtonEvent ce)
								{
									performSearch();
								}
							});

			btn.setEnabled(false);

			return btn;
		}

		protected HorizontalPanel buildSearchBar()
		{
			HorizontalPanel ret = new HorizontalPanel();

			ret.setStyleAttribute("margin-top", "5px");

			btnSearch = buildSearchButton();
			waitIcon = new Status();

			ret.add(btnSearch);
			ret.add(waitIcon);

			return ret;
		}

		protected void searchBegin()
		{
			waitIcon.setBusy("Searching");
			btnSearch.disable();
		}

		protected void searchComplete()
		{
			btnSearch.enable();
			waitIcon.clearStatus("");
		}

		protected boolean isValidSearchEntry(String entry)
		{
			boolean ret = false; // assume failure

			// this is a really basic test, I expect this to change in the future.
			if(entry != null && !entry.trim().isEmpty())
			{
				ret = true;
			}

			return ret;
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
			VerticalPanel pnlInner = new VerticalPanel();

			pnlInner.add(new Label(searchLabel));
			pnlInner.add(entrySearch);

			add(pnlInner);

			add(buildSearchBar());
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
					if(event.getKeyCode() == KeyCodes.KEY_ENTER)
					{
						performSearch();
					}

					boolean enabled = isValidSearchEntry(ret.getValue());
					btnSearch.setEnabled(enabled);
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
					searchComplete();
					String value = selectSearchType.getValue(selectSearchType.getSelectedIndex());

					if(value.equals(SEARCH_TYPE_FAMILY_ID))
					{
						showFamilyIdResult(result);
					}
					else
					{
						showSimpleResultsWindow("Results for term " + term + ":", result);
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
					boolean enabled = isValidSearchEntry(ret.getValue());
					btnSearch.setEnabled(enabled);
				}
			});

			return ret;
		}

		private void init()
		{
			areaSearch = buildSearchArea();
			setStyleAttribute("background-color", "#EDEDED");
		}

		private void compose()
		{
			VerticalPanel pnlInner = new VerticalPanel();

			// add type selection
			pnlInner.add(new Label("Protein or nucleotide sequence for gene of interest:"));

			// add search components
			pnlInner.add(areaSearch);

			add(pnlInner);
			add(buildSearchBar());
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
					searchComplete();
					showBlastResultsWindow("Results for BLAST search for entered sequence:", result);
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

	private void showResultsWindow(final String heading, final String results, boolean isBlast)
	{
		TRSearchResultsWindow window = TRSearchResultsWindow.getInstance();

		window.init(heading, results, isBlast, cmdView, searchService);

		window.show();
		window.toFront();
	}

	private void showSimpleResultsWindow(final String heading, final String results)
	{
		showResultsWindow(heading, results, false);
	}

	private void showBlastResultsWindow(String heading, String results)
	{
		showResultsWindow(heading, results, true);
	}

	/**
	 * Shows the tree viewer if the result contains a non-empty "name" value and a non-empty "gene_count"
	 * value. Otherwise, an error window is shown.
	 * 
	 * @param result
	 */
	private void showFamilyIdResult(String result)
	{
		JSONArray arr = TRUtil.parseItem(result).isArray();

		if(arr != null && arr.size() > 0)
		{
			JSONObject val = arr.get(0).isObject();
			if(val != null)
			{
				JSONString name = val.get("name").isString();
				if(name != null && !name.stringValue().isEmpty())
				{
					if(val.get("gene_count") != null)
					{
						cmdView.execute(name.stringValue());
						return;
					}
				}
			}
		}

		MessageBox.alert("Not Found", "The gene family ID was not found.", null);
	}
}
